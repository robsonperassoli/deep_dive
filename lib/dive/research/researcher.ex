defmodule Dive.Research.Researcher do
  require Logger

  alias Dive.Research.Source
  alias Dive.Crawl4AI
  alias Dive.Research.Topic
  alias Dive.OpenAI

  def search(%Topic{} = topic, listener_pid) do
    notify_listener(listener_pid, "🧠 Research started, coming up with good web searches")
    search_terms = get_search_query(topic.text)

    search_results =
      search_terms
      |> Enum.map(
        &Task.async(fn ->
          notify_listener(listener_pid, "🔎 Searching for #{&1}")

          results = search_web(&1)

          notify_listener(listener_pid, "🔎 Found #{Enum.count(results)} results for #{&1}")

          results
        end)
      )
      |> Task.await_many(60_000)
      |> List.flatten()
      |> Enum.uniq_by(& &1["url"])

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    search_results
    |> Enum.map(
      &%{
        topic_id: topic.id,
        url: &1["url"],
        search: &1["search_term"],
        title: &1["title"],
        inserted_at: now,
        updated_at: now
      }
    )
    |> then(&Dive.Repo.insert_all(Source, &1))

    topic =
      topic.id
      |> Dive.Research.get_topic!()
      |> Dive.Repo.preload(:sources)

    sources =
      topic.sources
      |> Task.async_stream(__MODULE__, :fetch_source_content, [listener_pid],
        timeout: 120_000,
        max_concurrency: 4,
        on_timeout: :kill_task
      )
      |> Enum.to_list()
      |> Enum.filter(&(elem(&1, 0) === :ok))
      |> Enum.map(&elem(&1, 1))
      |> Task.async_stream(__MODULE__, :summarize_source, [topic, listener_pid],
        timeout: 60_000,
        max_concurrency: 4,
        on_timeout: :kill_task
      )
      |> Enum.filter(&(elem(&1, 0) === :ok))
      |> Enum.map(&elem(&1, 1))
      |> Enum.reject(&is_nil(&1.summary))
      |> Enum.map(&web_page_summary(&1.url, &1.title, &1.summary))

    notify_listener(listener_pid, "🧠 Research done, building report.")

    final_report =
      final_report(topic.text, sources)

    topic
    |> Dive.Research.update_topic(%{
      report: final_report
    })

    notify_listener(listener_pid, :finished)

    {:ok, topic}
  end

  def search_web(search_term) do
    Dive.Search.search(search_term)
    |> Map.get("results")
    |> Enum.take(5)
    |> Enum.map(&Map.put(&1, "search_term", search_term))
  end

  def fetch_source_content(%Source{} = source, listener_pid) do
    notify_listener(listener_pid, "🌐 Checking #{source.title}")

    %{"task_id" => task_id} = Crawl4AI.crawl(source.url)

    {:ok, source} = Dive.Research.update_source(source, %{crawl_task_id: task_id})

    crawl_result =
      Task.async(fn ->
        Dive.Crawl4AI.get_task_or_wait_completion(task_id)
      end)
      |> Task.await(60_000)

    source
    |> Dive.Research.update_source(%{raw: Jason.encode!(crawl_result)})
    |> then(&elem(&1, 1))
  end

  def summarize_source(%Source{raw: raw, title: title} = source, %Topic{text: text}, listener_pid) do
    notify_listener(listener_pid, "🧠 Summarizing contents of #{title}")

    crawl = Jason.decode!(raw)

    summary =
      summarize_page(text, crawl["result"]["markdown_v2"]["markdown_with_citations"])

    notify_listener(listener_pid, "✅ Summary of #{title} ready")

    source
    |> Dive.Research.update_source(%{
      summary: summary
    })
    |> then(&elem(&1, 1))
  end

  def web_page_summary(url, title, content) do
    """
    Title: #{title}
    Summary: #{content}
    URL: #{url}
    """
  end

  def get_search_query(topic) do
    [
      %OpenAI.Message{
        role: :system,
        content: """
        You are a web search query optimizer. Your task is to transform user requests into effective search queries that will yield the most relevant results on search engines like Google or Bing.

        Follow these guidelines:
        1. Create 1-3 alternative search queries that would yield comprehensive results
        2. Structure queries following best practices for search engines (use quotes for exact phrases, include key modifiers)
        3. Include specific filters when appropriate (site:, filetype:, etc.)
        4. Consider search intent (informational, navigational, transactional)
        5. Format your response as a list of search queries without explanations
        6. If the query is ambiguous, provide variations that cover different interpretations
        7. The current date is: #{DateTime.utc_now() |> DateTime.to_date() |> Date.to_iso8601()}

        For example:
        - User request: "I need information about climate change impacts"
        - Response in JSON:
          {terms:["climate change impacts by region",
          "scientific evidence of climate change effects 2020-present",
          "climate change consequences agriculture economy"]}

        - User request: "Looking for Python machine learning tutorials"
        - Response in JSON:
          {terms:["beginner Python machine learning tutorial step by step",
          "Python scikit-learn TensorFlow tutorial examples",
          "Python machine learning projects with code GitHub"]}

        Prioritize queries that will return high-quality, authoritative results. Focus on precision terms that will narrow down to exactly what the user is seeking.
        """
      },
      %OpenAI.Message{
        role: :system,
        content: topic
      }
    ]
    |> OpenAI.chat_completion()
    |> then(fn %Req.Response{body: body} ->
      body["choices"]
      |> List.first()
      |> Map.get("message")
      |> Map.get("content")
      |> Jason.decode!()
      |> Map.get("terms")
    end)
  end

  def summarize_page(topic, content) do
    [
      %OpenAI.Message{
        role: :system,
        content: """
        Web Page Summarization System
        You are a specialized assistant that creates concise summaries of web pages found through user searches.

        Core Functions

        Produce clear, informative summaries preserving key information
        Format for readability and information hierarchy
        Adapt to different content types (news, research, product pages)

        Summary Format

        Title: Brief descriptive headline
        Key Points: 3-5 bullet points of essential information
        Brief Summary: 1-2 paragraphs capturing main context
        Source: Domain name and date when available

        Guidelines

        Focus on facts over opinions
        Maintain neutrality
        Preserve important data and statistics
        Flag outdated or potentially inaccurate information
        Use clear language accessible to most readers
        Scale summary length to match content complexity

        Your goal is to save users time while providing accurate understanding of web content.
        """
      },
      %OpenAI.Message{
        role: :system,
        content: """
        <web-page>
        #{content}
        </web-page>

        <user-search>
        #{topic}
        </user-search>
        """
      }
    ]
    |> OpenAI.chat_completion(json: false)
    |> then(fn
      %Req.Response{body: %{"choices" => choices}} when is_list(choices) ->
        choices
        |> List.first()
        |> Map.get("message")
        |> Map.get("content")

      %Req.Response{body: body} ->
        Logger.info("Empty response: #{inspect(body)}")
    end)
  end

  def final_report(topic, sources) do
    concat_sources =
      sources
      |> Enum.map(
        &"""
        <source>
        #{&1}
        </source>
        """
      )
      |> Enum.join("\n")

    [
      %OpenAI.Message{
        role: :system,
        content: """
        You are an expert research assistant that creates clear, comprehensive reports based on web search results. Your task is to organize and synthesize information from multiple sources into a cohesive, well-structured report.

        INSTRUCTIONS:
        1. Analyze all search results provided to extract key information relevant to the user's query
        2. Structure your report with appropriate headings, subheadings, and sections
        3. Include a brief executive summary at the beginning
        4. Present information objectively, avoiding bias or opinion
        5. Cite sources properly within the report using [Source X] format
        6. Highlight contradictory information when sources disagree
        7. Include a "Further Research" section suggesting additional topics or questions
        8. Always maintain factual accuracy - do not fabricate information
        9. Format the report professionally using Markdown
        10. Conclude with a bibliography listing all sources

        The user will provide search results in the following format:
        <topic>
          User search topic
        </topic>
        <source>
          search result summary extracted from a web page
        </source>

        Create a report in markdown format that best addresses the user's information needs based on these search results.
        """
      },
      %OpenAI.Message{
        role: :system,
        content: """
        <topic>
        #{topic}
        </topic>

        #{concat_sources}
        """
      }
    ]
    |> OpenAI.chat_completion(json: false)
    |> then(fn %Req.Response{body: body} ->
      body["choices"]
      |> List.first()
      |> Map.get("message")
      |> Map.get("content")
    end)
  end

  def notify_listener(nil, _message), do: :noop

  def notify_listener(pid, message) do
    if Process.alive?(pid) do
      send(pid, {__MODULE__, message})
    else
      Logger.warning("[#{__MODULE__}] Cannot notify listener, process not alive...",
        message: message
      )
    end
  end
end

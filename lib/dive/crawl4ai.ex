defmodule Dive.Crawl4AI do
  @base_url "http://localhost:11235"

  def crawl(url) do
    "#{@base_url}/crawl"
    |> Req.post!(
      json: %{
        urls: url,
        depth: 1,
        follow_links: false
      },
      headers: auth_header(),
      receive_timeout: 200_000,
      retry: :transient,
      max_retries: 2
    )
    |> then(fn
      %Req.Response{body: body} -> body
      e -> e
    end)
  end

  def get_task(task_id) do
    "#{@base_url}/task/#{task_id}"
    |> Req.get!(
      headers: auth_header(),
      receive_timeout: 200_000,
      retry: :transient,
      max_retries: 2
    )
    |> then(fn
      %Req.Response{body: body} -> body
      e -> e
    end)
  end

  def get_task_or_wait_completion(task_id) do
    task_id
    |> get_task()
    |> then(fn
      %{"status" => "completed"} = res ->
        res

      %{"status" => _} ->
        Process.sleep(1_000)
        get_task_or_wait_completion(task_id)

      err ->
        err
    end)
  end

  def auth_header() do
    %{"Authorization" => "Bearer " <> api_token()}
  end

  def api_token() do
    config()[:api_token]
  end

  def config() do
    Application.get_env(:dive, :crawl4ai)
  end
end

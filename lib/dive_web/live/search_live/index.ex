defmodule DiveWeb.SearchLive.Index do
  use DiveWeb, :live_view

  alias Dive.Research
  alias Dive.Research.ProgressReporter
  alias Dive.Research.Topic

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :topics, Research.list_topics())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Topic")
    |> assign(:topic, %Topic{})
    |> assign(:current_search, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:topic, nil)
    |> assign(:current_search, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    topic = Research.get_topic!(id)

    pid = self()

    if ProgressReporter.in_progress?(id) do
      ProgressReporter.register_listener(id, pid)
    else
      Task.start(fn ->
        Process.sleep(500)

        if ProgressReporter.in_progress?(id) do
          ProgressReporter.register_listener(id, pid)
        end
      end)
    end

    report_html =
      if topic.report do
        topic.report
        |> String.split("\n")
        |> Earmark.as_html!()
      end

    socket
    |> assign(:page_title, topic.text)
    |> assign(:report_html, report_html)
    |> assign(:topic, topic)
    |> assign(:current_search, nil)
  end

  @impl true
  def handle_info({DiveWeb.SearchLive.FormComponent, {:saved, topic}}, socket) do
    {:ok, pid} = ProgressReporter.start(topic.id)

    Task.start(fn ->
      Dive.search(topic, pid)
    end)

    dbg(["saved pid", self()])

    {:noreply,
     socket
     |> stream_insert(:topics, topic)
     |> assign(:current_search, [])}
  end

  @impl true
  def handle_info({ProgressReporter, :finished}, socket) do
    if socket.assigns.topic.id do
      topic = Research.get_topic!(socket.assigns.topic.id)

      report_html =
        if topic.report do
          topic.report
          |> String.split("\n")
          |> Earmark.as_html!()
        end

      {:noreply,
       socket
       |> assign(:topic, topic)
       |> assign(:report_html, report_html)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({ProgressReporter, notification}, socket) do
    IO.puts(notification)

    current_search = socket.assigns.current_search || []
    notifications = current_search ++ [notification]

    {:noreply,
     socket
     |> assign(:current_search, notifications)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Research.get_topic!(id)
    {:ok, _} = Research.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end
end

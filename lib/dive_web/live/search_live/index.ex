defmodule DiveWeb.SearchLive.Index do
  use DiveWeb, :live_view

  alias Dive.Research
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
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:topic, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    topic = Research.get_topic!(id)

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
  end

  @impl true
  def handle_info({DiveWeb.SearchLive.FormComponent, {:saved, topic}}, socket) do
    # TODO: add socker process id to search to get notifications back
    Dive.search(topic)
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Research.get_topic!(id)
    {:ok, _} = Research.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end
end

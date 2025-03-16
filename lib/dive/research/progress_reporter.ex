defmodule Dive.Research.ProgressReporter do
  use GenServer

  require Logger

  # Client
  def start(topic_id) do
    name = name(topic_id)

    name
    |> GenServer.whereis()
    |> then(fn
      nil ->
        GenServer.start(__MODULE__, %{listener_pid: nil, notifications: []}, name: name)

      pid when is_pid(pid) ->
        {:ok, pid}
    end)
  end

  def in_progress?(topic_id) do
    GenServer.whereis(name(topic_id))
    |> then(fn
      nil -> false
      _ -> true
    end)
  end

  def register_listener(topic_id, pid) do
    GenServer.cast(name(topic_id), {:register_listener, pid})
  end

  # Server
  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast({:register_listener, pid}, state) do
    {:noreply, Map.put(state, :listener_pid, pid)}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info({Dive.Research.Researcher, :finished}, state) do
    if not is_nil(state[:listener_pid]) do
      send(state[:listener_pid], {__MODULE__, :finished})
    end

    GenServer.cast(self(), :stop)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({Dive.Research.Researcher, text}, state) do
    Logger.info("[__MODULE__] Notifying pid #{inspect(state[:listener_pid])}")

    new_state =
      state
      |> Map.put(:notifications, state[:notifications] ++ [text])

    if not is_nil(state[:listener_pid]) do
      send(state[:listener_pid], {__MODULE__, text})
    end

    {:noreply, new_state}
  end

  defp name(topic_id) do
    :"reporter_#{topic_id}"
  end
end

defmodule StopWatch.HubAdapter do

  @moduledoc "Adapts the new Informant-based Stopwatch API to Hub"

  use GenServer
  alias Nerves.Hub

  @hub_path [:watch]
  @topic {:watch, 0}

  ## API

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  # GenServer Callbacks

  def init(_options) do
    Informant.subscribe(StopWatch, @topic)
    {:ok, true}
  end

  # Handle Informant Notifications

  def handle_info({:informant, StopWatch, @topic, event, _}, state) do
    handle_inform(event, state)
  end

  defp handle_inform({:join, pubstate, _}, state) do
    Hub.update(@hub_path, pubstate)
    Hub.manage(@hub_path)
    {:noreply, state}
  end
  defp handle_inform({:changes, changes, _meta}, state) do
    Hub.update(@hub_path, changes)
    {:noreply, state}
  end
  defp handle_inform(_other, state) do
    {:noreply, state}
  end

  ## Hub Handlers

  def handle_call({:request, _path, changes, _context}, _from, state) do
    changeset = {:changes, Map.new(changes)}
    reply = Informant.request(StopWatch, @topic, changeset)
    {:reply, reply, state}
  end

end

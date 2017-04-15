defmodule StopWatch.Server do

  @moduledoc """
  A simple stopwatch GenServer used for exploring the common pattern
  of autonomous GenServers that make notifications.

  Implements a basic counter with configurable resolution
  (down to 10ms).  Implements "go", "stop", and "clear" functions.  Also
  implements a "time" genserver call, to return the number of ms passed.
  Also takes a "resolution" parameter (in ms).

  This branch explores using *Informant* for notifications, with optional
  connections to Hub and HubRestAPI.
  """
  use GenServer

  @public_state_keys [:ticks, :msec, :resolution, :running]

  def start_link(params, _options \\ []) do
    # REVIEW WHY NEED NAME HERE?  Why can't pass as option?
    GenServer.start_link __MODULE__, params, name: :stop_watch
  end

  def init() do
    state=%{tref: nil, ticks: 0, running: false, resolution: 100}
    Informant.register {StopWatch, pid}
    announce(state)
    {:ok, tref} = :timer.send_after(state.resolution, :tick)
    {:ok, %{state | tref: tref}}
  end

  @doc "start the stopwatch"
  def go(pid),    do: GenServer.cast(pid, :go)

  @doc "stop the stopwatch"
  def stop(pid),  do: GenServer.cast(pid, :stop)

  @doc "clear the time on the stopwatch"
  def clear(pid), do: GenServer.cast(pid, :clear)

  @doc "get the current time of the stopwatch"
  def time(pid),  do: GenServer.call(pid, :time)

  @doc "set multiple attributes of the stopwatch"
  def set(pid, changes), do: GenServer.cast(pid, {:request, :changes})

  # public (server) genserver handlers, which modify state

  def handle_cast(:go, state) do
    {:ok, tref} = :timer.send_after(state.resolution, :tick)
    %{state | running: true, tref: tref} |> announce() |> noreply()
  end

  def handle_cast(:stop, state) do
    %{state | running: false} |> announce() |> noreply()
  end

  def handle_cast(:clear, state) do
    %{state | ticks: 0} |> announce() |> noreply()
  end

  def handle_call(:time, _from, state) do
    {:reply, state.ticks, state}
  end

  # request handler

  def handle_cast({:request, changes}, state) do
    new_state = Enum.reduce changes, old_state, fn({k,v}, state) ->
      handle_set(k,v,state)
    end
    {:noreply, new_state}
  end

  # request handler (hub compatible) - replies with new state

  def handle_call({:request, _path, changes, _context}, _from, old_state) do
    new_state = Enum.reduce changes, old_state, fn({k,v}, state) ->
      handle_set(k,v,state)
    end
    {:reply, :ok, new_state}
  end

  # handle setting "running" to true or false for go/stop (hub)
  def handle_set(:running, true, state) do
    if not state.running do
      cancel_any_current_timer(state)
      {:ok, tref} = :timer.send_after(state.resolution, :tick)
      announce(%{state | running: true, tref: tref})
    else
      state
    end
  end

  def handle_set(:running, false, state) do
    if state.running do
      cancel_any_current_timer(state)
      announce(%{state | running: false, tref: nil})
    else
      state
    end
  end

  # handle setting "ticks" to zero to clear (hub)
  def handle_set(:ticks, 0, state) do
    %{state | ticks: 0} |> announce()
  end


  # handle setting "resolution" (hub)
  # changes the resolution of the stopwatch.  Try to keep the current time
  # by computing a new tick count based on the new offset, and cancelling
  # timers.   Returns a new state
  def handle_set(:resolution, nr, state) do
    cur_msec = state.ticks * state.resolution
    cancel_any_current_timer(state)
    {:ok, tref} = :timer.send_after(nr, :tick)
    %{state | resolution: nr, ticks: div(cur_msec,nr), tref: tref}
    |> announce()
  end

  # catch-all for handling bogus properties

  def handle_set(_, _, state), do: state

  # internal (timing) genserver handlers

  def handle_info(:tick, state) do
    if state.running do
      {:ok, tref} = :timer.send_after(state.resolution, :tick)
      %{state | ticks: (state.ticks + 1), tref: tref}
      |> announce_time_only()
      |> noreply
    else
      {:noreply, state}
    end
  end

  # private helpers

  # cancel current timer if present, and set timer ref to nil
  defp cancel_any_current_timer(state) do
    if (state.tref) do
      {:ok, :cancel} = :timer.cancel state.tref
    end
    %{state | tref: nil}
  end

  # announce all public state, return all state so piplenes easy
  defp announce(state) do
    Informant.update {:stop_watch, 0}, (
      state
      |> Map.take(@public_state_keys)
      |> Map.merge(%{sec: (state.ticks * state.resolution)})
    )
    state
  end

  # announce just the time, return all state so pipelines easy
  defp announce_time_only(state) do
    Informant.update {:stop_watch, 0}, %{
      ticks: state.ticks,
      msec: (state.ticks * state.resolution)
    }
    state
  end

  # genserver response helpers to make pipe operator prettier

  defp noreply(state), do: {:noreply, state}
  defp reply(state, reply), do: {:reply, reply, state}

end

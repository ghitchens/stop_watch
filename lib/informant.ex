defmodule Informant do

  @moduledoc ~S"""


  """
  use GenServer

  ## API

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def update(key, value) do
    GenServer.call(__MODULE__, {:update, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def find(matchspec) do
    GenServer.call(__MODULE__, {:find, matchspec})
  end

  def register(matchspec) do
    GenServer.call(__MODULE__, {:register, matchspec})
  end

  def unregister(matchspec) do
    GenServer.call(__MODULE__, {:unregister, matchspec})
  end




  @doc ~S"""
  Updates public state with `updates`, computes and returns changes,
  and then triggers notifications.  Nonblocking/nonpre-emptive.

  # Important Characteristics

  - Atomicity of complex updates
  - Atomicity of notifications upon subscription
  - Subscription to fultiple topics

  WARNNING:  I have not convinced myself that this is concurrentcy-safe.
  Can a pre-emption happen between safely_update.... and notify?
  Can another notification be sent at this time?  Or is the calling
  process responsible for serializing updates?
  """
  def update(domain, updates, event_metadata \\ nil) do
    changes = safely_update_and_compute_changes(domain, updates)
    notify(domain, {:changes, changes}, {:update, self(), event_metadata})
    changes
  end

  def notify(domain, notification, metadata) do
    Genserver.cast(__MODULE__, {:notify, domain, event, metadata})
  end

  def handle_cast({:notify, domain, event}, from, state) do

  end
end

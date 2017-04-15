defmodule StopWatch.Application do

  use Application
  alias Nerves.HubRestApi

  @http_port 8888
  @api_prefix :api

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    dispatch = :cowboy_router.compile([	{:_, [
      {"/#{@api_prefix}/[...]", HubRestApi, []},
      {"/", :cowboy_static, {:priv_file, :stop_watch, "web/index.html"}},
      {"/[...]", :cowboy_static, {:priv_dir, :stop_watch, "web", [{:mimetypes, :cow_mimetypes, :all}]}}
    ]} ])
    {:ok, _pid} = :cowboy.start_http(:http, 10, [port: @http_port],
      [env: [dispatch: dispatch] ])
    children = [worker(StopWatch.Server, [], [name: :stop_watch])]
    Supervisor.start_link children, [strategy: :one_for_one, name: StopWatch.Supervisor]
  end

end

defmodule StopWatch.HubAdapter do

  @moduledoc "Adapts the new Informant-based Stopwatch API to Hub"

  use GenServer
  alias Nerves.Hub

  @hub_path [:watch]


  ## API

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  ## Callbacks

  def init(_options) do
    Informant.subscribe(StopWatch, :_)
    Hub.update(@hub_path, [running: false])
    {:ok, true}
  end

  ## Hub Handlers

  @doc false
  def handle_call({:request, _path, changes, _context}, _from, state) do
    StopWatch.request(changes) # REVIEW is it ok not to know state at this point?
    {:ok, state}
  end

  ## Stopwatch Informant Handlers

  def handle_info({:notify, source, changes, context}, state) do
    Hub.update @hub_path ++ [to_string(source)], changes, context
    {:ok, state} 
  end

end

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

  use GenServer
  alias Nerves.Hub

  @stop_watch_prefix :watch

  def start_link() do
    Hub.update([@stop_watch_prefix], [running: false])
    #Hub.manage([@stop_watch_prefix], [])
    spawn_link &run/0
  end

  # listen for informs of state changes, then update hub
  defp run() do
    receive do

         Hub.update([@stop_watch_prefix], changeset)
    end
    run()
  end

end

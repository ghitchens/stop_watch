defmodule StopWatch.Application do

  use Application
  alias Nerves.Hub
  alias Nerves.HubRestApi

  @http_port 8888
  @api_prefix :api
  @stop_watch_prefix :watch
  @http_path "localhost:#{@http_port}/#{@api_prefix}/#{@stop_watch_prefix}/"

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    dispatch = :cowboy_router.compile([	{:_, [
      {"/#{@api_prefix}/[...]", HubRestApi, []},
      {"/", :cowboy_static, {:priv_file, :stop_watch, "web/index.html"}},
      {"/[...]", :cowboy_static, {:priv_dir, :stop_watch, "web", [{:mimetypes, :cow_mimetypes, :all}]}}
    ]} ])
    {:ok, _pid} = :cowboy.start_http(:http, 10, [port: @http_port],
      [env: [dispatch: dispatch] ])
    children = [worker(StopWatch.Server, [startup_params], [name: :stop_watch])]
    Supervisor.start_link children, [strategy: :one_for_one, name: StopWatch.Supervisor]
  end

  defp startup_params, do: %{
    ticks: 0,
    running: false,
    resolution: 100,
    initializer: fn() ->
      Hub.update([@stop_watch_prefix], [running: false])
      Hub.manage([@stop_watch_prefix], [])
    end,
    announcer: &(Hub.update([@stop_watch_prefix], &1))
  }

end

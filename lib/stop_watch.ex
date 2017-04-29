defmodule StopWatch.Application do

  use Application

  @http_port 8888
  @api_prefix :api

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    dispatch = :cowboy_router.compile([	{:_, [
      {"/#{@api_prefix}/[...]", Nerves.HubRestApi, []},
      {"/", :cowboy_static, {:priv_file, :stop_watch, "web/index.html"}},
      {"/[...]", :cowboy_static, {:priv_dir, :stop_watch, "web", [{:mimetypes, :cow_mimetypes, :all}]}}
    ]} ])
    {:ok, _pid} = :cowboy.start_http(:http, 10, [port: @http_port],
      [env: [dispatch: dispatch] ])
    children = [worker(Informant, [StopWatch], []),
                worker(StopWatch.Server, [nil], [name: :stop_watch]),
                worker(StopWatch.HubAdapter, [nil], [])]
    Supervisor.start_link children, [strategy: :one_for_one, name: StopWatch.Supervisor]
  end

end

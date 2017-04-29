defmodule StopWatch.Mixfile do

  use Mix.Project

  def project, do: [
    app: :stop_watch,
    version: "0.2.0",
    elixir: "~> 1.4",
    deps: deps(Mix.env)
  ]

  def application, do: [
    mod:          { StopWatch.Application, [] },
    applications: [ :nerves_hub, :nerves_hub_rest_api ],
    env:          [ ]
  ]

  defp deps(:test), do: deps(:dev) ++ [
    { :httpotion, github: "myfreeweb/httpotion"}
  ]

  defp deps(_), do: [
    { :informant, github: "ghitchens/informant" },
    { :nerves_hub, github: "nerves-project/nerves_hub" },
    { :nerves_hub_rest_api, github: "nerves-project/nerves_hub_rest_api" },
  ]

end

defmodule ProjectBookclub.MixProject do
  use Mix.Project

  def project do
    [
      app: :project_bookclub,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ProjectBookclub.Application, []}
    ]
  end

  # The read side: evoq and sqlite. NO Phoenix, NO mesh SDK.
  defp deps do
    [
      {:evoq, "~> 1.24"},
      {:esqlite, "~> 0.9"}
    ]
  end
end

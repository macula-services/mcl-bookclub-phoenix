defmodule QueryBookclub.MixProject do
  use Mix.Project

  def project do
    [
      app: :query_bookclub,
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
      mod: {QueryBookclub.Application, []}
    ]
  end

  # Pure reads over sqlite. NO Phoenix, NO evoq, NO mesh SDK -- a QRY
  # module that names them would not compile.
  defp deps do
    [
      {:esqlite, "~> 0.9"}
    ]
  end
end

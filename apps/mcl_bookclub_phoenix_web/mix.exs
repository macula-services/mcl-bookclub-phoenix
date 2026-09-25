defmodule MclBookclubPhoenixWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcl_bookclub_phoenix_web,
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
      mod: {MclBookclubPhoenixWeb.Application, []}
    ]
  end

  # Presentation ONLY. The LiveView admin calls the divisions through the
  # same entry points the mesh uses: host_bookclub's maybe_ desks for
  # every task button, query_bookclub's query desks for every lookup.
  # project_bookclub is a dep because the LiveView subscribes to the
  # pubsub registry that app owns -- and the boot order the dep
  # guarantees is what makes that registry exist before this app starts.
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_pubsub, "~> 2.3"},
      {:bandit, "~> 1.12"},
      {:jason, "~> 1.4"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:host_bookclub, in_umbrella: true},
      {:project_bookclub, in_umbrella: true},
      {:query_bookclub, in_umbrella: true}
    ]
  end
end

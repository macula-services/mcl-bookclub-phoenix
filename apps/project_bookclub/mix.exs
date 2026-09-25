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

  # The read side: evoq and sqlite, plus the pubsub seam. NO Phoenix, NO
  # mesh SDK. phoenix_pubsub is deliberately NOT the web framework -- just
  # the pubsub library, so this PRJ app can broadcast each projected write
  # ("changed") without depending on the web app. LiveViews subscribe and
  # react; they never call this app directly. See macula-io/CLAUDE.md's
  # "Phoenix LiveView Architecture" rule.
  #
  # host_bookclub is an in_umbrella dep for ONE thing: each projection
  # reads its aggregate's readable status name from the CMD status module
  # (the flag maps live there -- Demon 68). Those are pure functions, so
  # this boots nothing mesh-facing into the PRJ app's tree: host_bookclub's
  # own emitters live in the facade, not here.
  defp deps do
    [
      {:evoq, "~> 1.24"},
      {:esqlite, "~> 0.9"},
      {:phoenix_pubsub, "~> 2.3"},
      {:host_bookclub, in_umbrella: true}
    ]
  end
end

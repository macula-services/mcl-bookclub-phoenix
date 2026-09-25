defmodule MclBookclubPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcl_bookclub_phoenix,
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
      extra_applications: [:crypto, :logger],
      mod: {MclBookclubPhoenix.Application, []}
    ]
  end

  # The facade: the mcl_om contract, the mesh face (facts + emitters +
  # capabilities) and the divisions it wires. macula and evoq are declared
  # directly because the emitters call :macula.publish/:macula_topic and
  # the supervisor starts :evoq_event_handler children.
  defp deps do
    [
      {:mcl_om, "~> 0.28"},
      {:macula, "~> 12.2"},
      {:evoq, "~> 1.24"},
      {:host_bookclub, in_umbrella: true},
      {:project_bookclub, in_umbrella: true},
      {:query_bookclub, in_umbrella: true}
    ]
  end
end

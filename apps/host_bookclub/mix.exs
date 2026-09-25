defmodule HostBookclub.MixProject do
  use Mix.Project

  def project do
    [
      app: :host_bookclub,
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
      mod: {HostBookclub.Application, []}
    ]
  end

  # The write side: evoq and reckon. NO Phoenix, NO mesh SDK -- the
  # division boundary is the dependency list.
  defp deps do
    [
      {:evoq, "~> 1.24"},
      {:reckon_evoq, "~> 2.7"},
      {:reckon_gater, "~> 3.11"}
    ]
  end
end

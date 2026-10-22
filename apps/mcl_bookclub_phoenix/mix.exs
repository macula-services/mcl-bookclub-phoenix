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
      # 1.4 is the macula-16 line on wire 1.0, the fleet's since the flag day
      # (2026-10-19). The major moves with the wire so no ~> 0.x service
      # floats onto a new wire by itself (mcl-om#27); a 1.0 node neither reads
      # a 14 node's frames nor handshakes with it, so this is taken on
      # purpose, as every other service took it.
      {:mcl_om, "~> 1.4"},
      {:macula, "~> 16.0"},
      # THIS SERVICE'S OWN EVENT STORE. mcl_om opens no store and starts no
      # reckon-db or evoq application since 0.35.0 (mcl-om#10): the three
      # persistence apps are this app's own deps, and
      # MclBookclubPhoenix.Application opens the store in start/2 before
      # mcl_om:boot/1. Leaving them out compiles clean and boots with no
      # store at all.
      {:reckon_db, "~> 5.11"},
      {:evoq, "~> 1.27"},
      {:reckon_evoq, "~> 2.8"},
      {:host_bookclub, in_umbrella: true},
      {:project_bookclub, in_umbrella: true},
      {:query_bookclub, in_umbrella: true},
      # The start-up ordering test replaces :mcl_om.boot/1 and the service's
      # event_store/0 for one call, so it can prove the store is open when
      # boot runs. Everything else passes through.
      {:meck, "~> 1.2", only: :test}
    ]
  end
end

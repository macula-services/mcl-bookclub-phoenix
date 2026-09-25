defmodule MclBookclubPhoenixUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      elixirc_options: elixirc_options(),
      deps: deps(),
      releases: releases(),
      dialyzer: dialyzer()
    ]
  end

  defp releases do
    [
      mcl_bookclub_phoenix: [
        # Every app in the umbrella must be listed explicitly here --
        # `mix release` does NOT auto-include the rest just because
        # they're present under apps/. Adding a new umbrella app and
        # forgetting to add it here compiles fine and boots fine (`mix
        # phx.server`/`mix run` don't have this restriction), then
        # silently excludes it from the actual release with no error --
        # the whiteboard found this the hard way when its web app's
        # Endpoint never started inside the built container. Listed in
        # boot order: the departments, then the service (whose
        # mcl_om:boot/1 opens the store), then the web app.
        applications: [
          host_bookclub: :permanent,
          project_bookclub: :permanent,
          query_bookclub: :permanent,
          mcl_bookclub_phoenix: :permanent,
          mcl_bookclub_phoenix_web: :permanent
        ]
      ]
    ]
  end

  defp elixirc_options do
    [
      # The house rule, the Elixir way: a warning is a refusal to ship.
      warnings_as_errors: true
    ]
  end

  # Declared once at the umbrella root: every apps/*/mix.exs points
  # deps_path/build_path at ../../, so `mix credo` and `mix dialyzer` from
  # the root cover every app (same layout as mcl-whiteboard).
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      # macula and reckon_db ship beams without debug_info (NIF-heavy
      # rebar3 packages), so the PLT cannot scan them; calls into them are
      # untyped from dialyzer's side.
      plt_ignore_apps: [:macula, :reckon_db],
      plt_core_path: "priv/plts/core",
      plt_local_path: "priv/plts/local",
      ignore_warnings: ".dialyzer_ignore.exs",
      flags: [:unmatched_returns, :error_handling]
    ]
  end
end

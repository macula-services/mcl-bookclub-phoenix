defmodule ProjectBookclub.DivisionBoundaryTest do
  # The Demon 68 boundary, as a mechanism: a readable-status literal
  # spelled out as a single-quoted SQL value in any PRJ source is the
  # relapse -- the projections must take each status string from the CMD
  # status module's flag map, never spell one out here. Only the quoted
  # forms count: the bare words legitimately appear in event-type names
  # ("book_retired_v1") and column names ("finished_at"); a status VALUE
  # is always a quoted literal. Comments count too: naming the literal in
  # prose is how the drift starts.
  use ExUnit.Case, async: true

  @forbidden [
    "'active'",
    "'archived'",
    "'on_shelf'",
    "'retired'",
    "'in_progress'",
    "'finished'",
    "'unregistered'"
  ]

  test "no PRJ source spells out a readable-status literal" do
    lib_dir = Path.expand("../lib", __DIR__)

    for path <- Path.wildcard(Path.join(lib_dir, "**/*.ex")),
        literal <- @forbidden do
      source = File.read!(path)

      refute String.contains?(source, literal),
             "#{literal} in #{Path.relative_to(path, lib_dir)} -- take the status" <>
               " string from the CMD status module's flag map instead"
    end
  end
end

# Dialyzer ignore file (term format, see deps/dialyxir/README.md).
#
# Every entry is a known finding that is not a defect in this repository.
[
  # macula ships its beams without debug_info (a NIF-heavy rebar3 package),
  # so it is excluded from the PLT (`plt_ignore_apps` in mix.exs). Dialyzer
  # then cannot see macula's functions or the callbacks of its behaviours.
  # Calls into macula are untyped from here; nothing else is hidden.
  ~r/Callback info about the :macula_response behaviour is not available/,
  ~r/Function :macula(_topic)?\.[a-z_]+\/\d+ does not exist/,
  # reckon_db is excluded from the PLT for the same reason, so the store
  # wiring's calls into reckon_db_sup (start the store, list it) and its
  # health probe into reckon_db_store are untyped from here.
  ~r/Function :reckon_db_(sup|store)\.[a-z_]+\/\d+ does not exist/
]

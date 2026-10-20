# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The walking skeleton: `initiate_bookclub_v1` dispatches to
  `BookclubAggregate` on its own reckon-db stream, `bookclub_initiated_v1`
  projects into a sqlite `clubs` table, and `get_bookclub_by_id` answers.
- The umbrella shape: `host_bookclub` (CMD), `project_bookclub` (PRJ),
  `query_bookclub` (QRY), `mcl_bookclub_phoenix` (the mcl_om facade) —
  business logic and presentation separated by the dependency graph.
- The full domain, mirroring the Erlang twin desk for desk:
  `archive_bookclub_v1`, `plan_party_v1`, `register_member_v1`/
  `unregister_member_v1`, `procure_book_v1`/`retire_book_v1`,
  `start_reading_v1`/`finish_reading_v1` — each aggregate (club, book,
  member, reading) with a blanket lifecycle guard over evoq bit flags,
  each soft-delete event self-contained, each dispatch validating the
  stream id at the boundary (Demon 67), and the
  `on_member_registered_v1_maybe_plan_party` policy as a sibling slice of
  the CMD app.
- The PRJ division's full read model: `members`, `books` and `readings`
  tables beside `clubs`, one idempotent projection per event, and the
  pubsub seam — every successful write broadcasts "changed" on a
  `MclBookclubPhoenixWeb.PubSub` registry the PRJ app owns, so the LiveView
  admin updates live instead of polling (the whiteboard's pattern).
- The QRY division's remaining desks: `get_book_by_id`,
  `get_member_by_id`, `get_reading_by_id`, `get_readings_by_member`.
- The facade's mesh face: the facts module (`member_registered_v1`,
  `book_procured_v1`, `book_retired_v1` on the SAME topics as the Erlang
  twin), three emitters with `replay_policy :skip` and evoq-retried
  publishes, and the `get_bookclub_by_id` capability answered through
  `mcl_om_wire:field/2` (Demon 65). The identity spec names the procedure
  and the three fact topics.
- The LiveView admin (`mcl_bookclub_phoenix_web`): the Erlang admin's
  task-based console, presentation only — every task button dispatches
  the division's entry point, every lookup calls a query desk, and the
  live feed subscribes to the projection pubsub seam.

### Changed

- **Wire 1.0: `mcl_om` 1.2 and macula 15.6, the line the fleet runs since
  the flag day (2026-10-19).** A wire 1.0 node neither reads a 14 node's
  frames nor completes a handshake with it, so this is taken on purpose: the
  `~> 0.x` floor could not float here on its own (mcl-om#27). No call site
  changed.
- **The facade opens its own reckon-db store before it boots the service.**
  `mcl_om` opens no store since 0.35.0 (mcl-om#10): a service module
  exporting `store_id/0` and `data_dir/0` no longer gets one, and only a
  warning at boot names the callbacks. `MclBookclubPhoenix.Application.start/2`
  now opens the store first (`MclBookclubPhoenix.EventStore`), waits until
  reckon-db lists it, and starts the per-store evoq subscription; the store's
  id, directory, indexes, mode and integrity live in
  `MclBookclubPhoenix.Service.event_store/0`, and the app declares
  `reckon_db`, `evoq` and `reckon_evoq` itself. Without this the bump
  compiles clean, boots green and has no store at all, losing every command
  and projection at its first touch.
- The readable status strings now live with their flags: each status
  module owns a flag map and `to_string/1` (rendered through
  `evoq_bit_flags:to_string/2`), and the projections take each status
  string from there instead of spelling SQL literals — Demon 68 in the
  corpus. A boundary test refuses a quoted status literal in any PRJ
  source, and the PRJ app depends on the CMD app's pure modules, not on
  booting the app.

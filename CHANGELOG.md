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

- The readable status strings now live with their flags: each status
  module owns a flag map and `to_string/1` (rendered through
  `evoq_bit_flags:to_string/2`), and the projections take each status
  string from there instead of spelling SQL literals — Demon 68 in the
  corpus. A boundary test refuses a quoted status literal in any PRJ
  source, and the PRJ app depends on the CMD app's pure modules, not on
  booting the app.

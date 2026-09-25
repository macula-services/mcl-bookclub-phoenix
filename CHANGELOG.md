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

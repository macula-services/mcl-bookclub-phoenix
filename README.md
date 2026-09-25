# mcl-bookclub-phoenix

**The Bookclub-on-Mesh, for Elixir students: the same domain, the same
contract, in Elixir with a Phoenix LiveView admin.**

This is the drop-in Elixir twin of
[mcl-bookclub](https://github.com/macula-services/mcl-bookclub): the same
commands, events, guards, stream ids, facts topics and procedure names —
a second club on the mesh, indistinguishable from the first except by node
identity. The contract is shared; the club is a payload parameter
(`club_id` and `club_name` in every fact), never a namespace. One topic
set serves a thousand clubs.

## Separation of business logic and presentation

The spine of this repository, by design and by test: the three division
apps (`host_bookclub`, `project_bookclub`, `query_bookclub`) have **no
Phoenix in their deps** — business logic never imports presentation. The
LiveView app contains only presentation, and calls the divisions through
the same entry points the mesh uses. A view that can't reach a guard is a
view that can't violate one.

## Layout

```
apps/host_bookclub/             CMD: commands, events, aggregates (Elixir structs)
apps/project_bookclub/          PRJ: events -> sqlite, idempotent writes + the pubsub seam
apps/query_bookclub/            QRY: pure query modules
apps/mcl_bookclub_phoenix/      the facade (the :mcl_om_service behaviour + mesh emitters)
apps/mcl_bookclub_phoenix_web/  the LiveView admin (presentation only)
```

## Status: full domain + LiveView admin

Every desk the Erlang twin has (initiate/archive/plan_party, member
register/unregister, book procure/retire, reading start/finish, the
plan_party policy), every projection (clubs/members/books/readings), every
query desk, the three mesh emitters, the `get_bookclub_by_id` capability,
and the LiveView admin console -- task buttons dispatch the divisions'
entry points, lookups call the query desks, and the projection pubsub seam
feeds the live feed. Remaining: CI workflows + Containerfile + the fleet
rollout as the second club.

## Running it

    mix deps.get
    mix compile --warnings-as-errors
    mix test
    mix credo --strict
    mix dialyzer

The runtime is pinned in `.tool-versions` (OTP 28.4.3, Elixir 1.18.4).
The admin serves on `MCL_HTTP_PORT` (default 4000); build its JS first
with `mix esbuild mcl_bookclub_phoenix_web`.

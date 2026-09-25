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
apps/host_bookclub/         CMD: commands, events, aggregates (Elixir structs)
apps/project_bookclub/      PRJ: events -> sqlite, idempotent writes
apps/query_bookclub/        QRY: pure query modules
apps/mcl_bookclub_phoenix/  the facade (the :mcl_om_service behaviour) + LiveView
```

## Status: walking skeleton

The first vertical slice: `initiate_bookclub_v1` dispatches on its own
reckon-db stream, `bookclub_initiated_v1` projects into sqlite, and
`get_bookclub_by_id` answers. The remaining desks, the emitters, the mesh
capabilities and the LiveView admin follow the shapes this slice
established.

## Running it

    mix deps.get
    mix compile --warnings-as-errors
    mix test
    mix credo --strict
    mix dialyzer

The runtime is pinned in `.tool-versions` (OTP 28.4.3, Elixir 1.18.4).

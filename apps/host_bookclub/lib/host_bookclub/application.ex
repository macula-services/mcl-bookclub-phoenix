defmodule HostBookclub.Application do
  # OTP application entry for the CMD division. Aggregates are started on
  # demand by evoq; the policies land here as supervised evoq_event_handler
  # children. The mesh emitters are NOT children here -- this division has
  # no mesh SDK in its deps, so the emitters live in the facade (see
  # mcl_bookclub_phoenix's supervisor).
  @moduledoc false

  use Application

  alias HostBookclub.OnMemberRegisteredV1MaybePlanParty

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: OnMemberRegisteredV1MaybePlanParty,
        start: {:evoq_event_handler, :start_link, [OnMemberRegisteredV1MaybePlanParty, %{}]},
        restart: :permanent,
        shutdown: 5_000,
        type: :worker,
        modules: [OnMemberRegisteredV1MaybePlanParty]
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: HostBookclub.Supervisor)
  end
end

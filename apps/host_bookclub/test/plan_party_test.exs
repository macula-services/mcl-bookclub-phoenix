defmodule HostBookclub.PlanPartyTest do
  # The plan_party slice: the command, the absolute-count event, the state
  # fold, the desk rule and the aggregate's blanket guard. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.BookclubState
  alias HostBookclub.PlanParty.{MaybePlanParty, PartyPlannedV1, PlanPartyV1}

  defp club_id, do: "bookclub-#{String.duplicate("a", 32)}"

  defp initiated_state do
    BookclubState.apply_event(BookclubState.new(club_id()), %{
      event_type: "bookclub_initiated_v1",
      name: "The Crooked Shelf",
      initiated_by: "bea"
    })
  end

  test "a command needs a club id" do
    assert {:error, :missing_required_fields} = PlanPartyV1.new(%{})
    {:ok, cmd} = PlanPartyV1.new(%{club_id: club_id()})
    assert :ok = PlanPartyV1.validate(cmd)
  end

  test "a human name is refused as the stream id" do
    {:ok, cmd} = PlanPartyV1.new(%{club_id: "the-crooked-shelf"})
    assert {:error, _} = PlanPartyV1.validate(cmd)
  end

  test "the event carries the club's NEW count as an absolute assignment" do
    {:ok, event} = PartyPlannedV1.new(%{club_id: club_id(), parties_planned: 3})
    map = PartyPlannedV1.to_map(event)
    assert map.event_type == "party_planned_v1"
    assert map.parties_planned == 3
    assert is_integer(map.planned_at)
  end

  test "the state folds the party tally from both event shapes" do
    raw =
      BookclubState.apply_event(initiated_state(), %{
        event_type: "party_planned_v1",
        parties_planned: 2
      })

    assert raw.parties_planned == 2

    enveloped =
      BookclubState.apply_event(initiated_state(), %{
        event_type: "party_planned_v1",
        data: %{parties_planned: 7}
      })

    assert enveloped.parties_planned == 7
  end

  test "the desk increments the count in the state it runs against" do
    state =
      BookclubState.apply_event(initiated_state(), %{
        event_type: "party_planned_v1",
        parties_planned: 4
      })

    {:ok, cmd} = PlanPartyV1.new(%{club_id: club_id()})

    assert {:ok, [event]} = MaybePlanParty.handle(state, cmd)
    assert event.parties_planned == 5
  end

  test "the desk refuses to plan a party for a club that was never initiated" do
    {:ok, cmd} = PlanPartyV1.new(%{club_id: club_id()})
    assert {:error, :not_initiated} = MaybePlanParty.handle(BookclubState.new(club_id()), cmd)
  end
end

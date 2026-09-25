defmodule HostBookclub.OnMemberRegisteredV1MaybePlanPartyTest do
  # The plan_party policy's pure half: the cadence decision and the
  # handler's contract shape. The dispatch side (every fifth registration
  # plans a party on the club's stream) is exercised end to end by the
  # running service, not here.
  use ExUnit.Case, async: true

  alias HostBookclub.OnMemberRegisteredV1MaybePlanParty

  test "interested in exactly the member_registered_v1 event" do
    assert OnMemberRegisteredV1MaybePlanParty.interested_in() == ["member_registered_v1"]
  end

  # A policy dispatches commands -- a side effect. Replaying it on a
  # restart would plan duplicate parties, so it must declare :skip.
  test "the policy skips replay" do
    assert OnMemberRegisteredV1MaybePlanParty.replay_policy() == :skip
  end

  test "the counter starts at zero" do
    assert {:ok, %{registrations: 0}} = OnMemberRegisteredV1MaybePlanParty.init(%{})
  end
end

defmodule HostBookclub.UnregisterMemberTest do
  # The unregister_member slice: the command, the self-contained event,
  # the state fold and the desk rule. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.MemberState

  alias HostBookclub.UnregisterMember.{
    MaybeUnregisterMember,
    MemberUnregisteredV1,
    UnregisterMemberV1
  }

  defp member_id, do: "member-#{String.duplicate("a", 32)}"
  defp club_id, do: "bookclub-#{String.duplicate("b", 32)}"

  defp registered_state do
    MemberState.apply_event(MemberState.new(member_id()), %{
      event_type: "member_registered_v1",
      club_id: club_id(),
      name: "Bea",
      registered_at: 42
    })
  end

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             UnregisterMemberV1.new(%{member_id: member_id()})

    assert {:error, :invalid_params} =
             UnregisterMemberV1.new(%{member_id: member_id(), unregistered_by: ""})
  end

  test "the event echoes the member's birth details" do
    {:ok, event} =
      MemberUnregisteredV1.new(%{
        member_id: member_id(),
        club_id: club_id(),
        name: "Bea",
        registered_at: 42,
        unregistered_by: "raf"
      })

    map = MemberUnregisteredV1.to_map(event)
    assert map.event_type == "member_unregistered_v1"
    assert map.club_id == club_id()
    assert map.name == "Bea"
    assert map.registered_at == 42
    assert map.unregistered_by == "raf"
    assert is_integer(map.unregistered_at)
  end

  test "the state folds the unregistered bit from both event shapes" do
    raw = MemberState.apply_event(registered_state(), %{event_type: "member_unregistered_v1"})
    assert MemberState.unregistered?(raw)

    enveloped =
      MemberState.apply_event(registered_state(), %{
        event_type: "member_unregistered_v1",
        data: %{unregistered_by: "raf"}
      })

    assert MemberState.unregistered?(enveloped)
  end

  test "the desk refuses to unregister a member that never registered" do
    {:ok, cmd} = UnregisterMemberV1.new(%{member_id: member_id(), unregistered_by: "raf"})

    assert {:error, :not_registered} =
             MaybeUnregisterMember.handle(MemberState.new(member_id()), cmd)
  end
end

defmodule HostBookclub.RegisterMemberTest do
  # The register_member slice: the command, the self-contained event, the
  # state fold, the desk rule and the aggregate's blanket guard. Pure, no
  # store.
  use ExUnit.Case, async: true

  alias HostBookclub.MemberAggregate
  alias HostBookclub.MemberState
  alias HostBookclub.RegisterMember.{MaybeRegisterMember, MemberRegisteredV1, RegisterMemberV1}

  defp member_id, do: "member-#{String.duplicate("a", 32)}"
  defp club_id, do: "bookclub-#{String.duplicate("b", 32)}"

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             RegisterMemberV1.new(%{member_id: member_id(), name: "Bea"})

    assert {:error, :invalid_params} =
             RegisterMemberV1.new(%{member_id: member_id(), club_id: club_id(), name: ""})
  end

  test "a minted member id satisfies the stream contract" do
    minted = RegisterMemberV1.mint_member_id()
    assert :ok = :reckon_gater_stream_id.validate(minted)

    {:ok, cmd} =
      RegisterMemberV1.new(%{member_id: minted, club_id: club_id(), name: "Bea"})

    assert :ok = RegisterMemberV1.validate(cmd)
  end

  test "the club_name rides along, defaulting to empty" do
    {:ok, cmd} =
      RegisterMemberV1.new(%{member_id: member_id(), club_id: club_id(), name: "Bea"})

    assert cmd.club_name == ""

    {:ok, named} =
      RegisterMemberV1.new(%{
        member_id: member_id(),
        club_id: club_id(),
        name: "Bea",
        club_name: "The Crooked Shelf"
      })

    assert named.club_name == "The Crooked Shelf"
  end

  test "the event is a self-contained fact" do
    {:ok, event} =
      MemberRegisteredV1.new(%{
        member_id: member_id(),
        club_id: club_id(),
        name: "Bea",
        club_name: "The Crooked Shelf"
      })

    map = MemberRegisteredV1.to_map(event)
    assert map.event_type == "member_registered_v1"
    assert map.club_id == club_id()
    assert map.club_name == "The Crooked Shelf"
    assert is_integer(map.registered_at)
  end

  test "the state folds both event shapes" do
    state = MemberState.new(member_id())
    refute MemberState.registered?(state)

    raw =
      MemberState.apply_event(state, %{
        event_type: "member_registered_v1",
        club_id: club_id(),
        name: "Bea"
      })

    assert MemberState.registered?(raw)
    assert raw.name == "Bea"

    enveloped =
      MemberState.apply_event(MemberState.new(member_id()), %{
        event_type: "member_registered_v1",
        data: %{club_id: club_id(), name: "Enveloped"}
      })

    assert MemberState.registered?(enveloped)
    assert enveloped.name == "Enveloped"
  end

  test "the desk refuses a second registration" do
    {:ok, cmd} =
      RegisterMemberV1.new(%{member_id: member_id(), club_id: club_id(), name: "Bea"})

    registered =
      MemberState.apply_event(MemberState.new(member_id()), %{
        event_type: "member_registered_v1",
        club_id: club_id(),
        name: "Bea"
      })

    assert {:error, :already_registered} = MaybeRegisterMember.handle(registered, cmd)
  end

  test "the aggregate's blanket guard refuses every command on an unregistered member" do
    unregistered =
      MemberState.apply_event(MemberState.new(member_id()), %{
        event_type: "member_registered_v1",
        club_id: club_id(),
        name: "Bea"
      })
      |> MemberState.apply_event(%{event_type: "member_unregistered_v1"})

    assert {:error, :unregistered} =
             MemberAggregate.execute(unregistered, %{
               command_type: :unregister_member_v1,
               member_id: member_id()
             })
  end
end

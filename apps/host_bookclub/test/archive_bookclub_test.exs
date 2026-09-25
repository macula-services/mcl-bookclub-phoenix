defmodule HostBookclub.ArchiveBookclubTest do
  # The archive slice: the command, the self-contained event, the state
  # fold, the desk rule and the aggregate's blanket guard. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.ArchiveBookclub.{ArchiveBookclubV1, BookclubArchivedV1, MaybeArchiveBookclub}
  alias HostBookclub.BookclubAggregate
  alias HostBookclub.BookclubState

  defp club_id, do: "bookclub-#{String.duplicate("a", 32)}"

  defp initiated_state do
    BookclubState.apply_event(BookclubState.new(club_id()), %{
      event_type: "bookclub_initiated_v1",
      name: "The Crooked Shelf",
      initiated_by: "bea"
    })
  end

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             ArchiveBookclubV1.new(%{club_id: club_id()})

    assert {:error, :invalid_params} =
             ArchiveBookclubV1.new(%{club_id: club_id(), archived_by: ""})
  end

  test "a human name is refused as the stream id" do
    {:ok, cmd} = ArchiveBookclubV1.new(%{club_id: "the-crooked-shelf", archived_by: "raf"})
    assert {:error, _} = ArchiveBookclubV1.validate(cmd)
  end

  test "the event is self-contained: it echoes the club's birth details" do
    {:ok, event} =
      BookclubArchivedV1.new(%{
        club_id: club_id(),
        name: "The Crooked Shelf",
        initiated_by: "bea",
        initiated_at: 42,
        archived_by: "raf"
      })

    map = BookclubArchivedV1.to_map(event)
    assert map.event_type == "bookclub_archived_v1"
    assert map.name == "The Crooked Shelf"
    assert map.initiated_by == "bea"
    assert map.initiated_at == 42
    assert map.archived_by == "raf"
    assert is_integer(map.archived_at)
  end

  test "the state folds both event shapes for the archived bit" do
    state = initiated_state()
    refute BookclubState.archived?(state)

    raw = BookclubState.apply_event(state, %{event_type: "bookclub_archived_v1"})
    assert BookclubState.archived?(raw)

    enveloped =
      BookclubState.apply_event(initiated_state(), %{
        event_type: "bookclub_archived_v1",
        data: %{archived_by: "raf"}
      })

    assert BookclubState.archived?(enveloped)
  end

  test "the desk refuses to archive a club that was never initiated" do
    {:ok, cmd} = ArchiveBookclubV1.new(%{club_id: club_id(), archived_by: "raf"})

    assert {:error, :not_initiated} =
             MaybeArchiveBookclub.handle(BookclubState.new(club_id()), cmd)
  end

  test "the aggregate's blanket guard refuses every command on an archived club" do
    archived = BookclubState.apply_event(initiated_state(), %{event_type: "bookclub_archived_v1"})

    assert {:error, :archived} =
             BookclubAggregate.execute(archived, %{
               command_type: :plan_party_v1,
               club_id: club_id()
             })

    assert {:error, :archived} =
             BookclubAggregate.execute(archived, %{
               command_type: :archive_bookclub_v1,
               club_id: club_id()
             })
  end
end

defmodule HostBookclub.InitiateBookclubTest do
  # The walking skeleton's CMD slice: the command, the event, the state
  # fold, and the validate-before-dispatch boundary. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.BookclubState
  alias HostBookclub.InitiateBookclub.{BookclubInitiatedV1, InitiateBookclubV1}

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             InitiateBookclubV1.new(%{name: "N", initiated_by: "raf"})

    assert {:error, :invalid_params} =
             InitiateBookclubV1.new(%{club_id: "bookclub-x", name: "", initiated_by: "raf"})
  end

  test "a minted club id satisfies the stream contract" do
    club_id = InitiateBookclubV1.mint_club_id()
    assert :ok = :reckon_gater_stream_id.validate(club_id)

    {:ok, cmd} =
      InitiateBookclubV1.new(%{club_id: club_id, name: "The Crooked Shelf", initiated_by: "raf"})

    assert :ok = InitiateBookclubV1.validate(cmd)
  end

  test "a human name is refused as the stream id" do
    {:ok, cmd} =
      InitiateBookclubV1.new(%{club_id: "the-crooked-shelf", name: "N", initiated_by: "raf"})

    assert {:error, _} = InitiateBookclubV1.validate(cmd)
  end

  test "the event is a self-contained fact" do
    {:ok, event} =
      BookclubInitiatedV1.new(%{club_id: "bookclub-1", name: "N", initiated_by: "raf"})

    map = BookclubInitiatedV1.to_map(event)
    assert map.event_type == "bookclub_initiated_v1"
    assert map.name == "N"
    assert is_integer(map.initiated_at)
  end

  test "the state folds both event shapes" do
    state = BookclubState.new("bookclub-1")
    refute BookclubState.initiated?(state)

    # The raw shape: business fields inline, right after execute/2.
    raw = BookclubState.apply_event(state, %{event_type: "bookclub_initiated_v1", name: "Inline"})
    assert BookclubState.initiated?(raw)
    assert raw.name == "Inline"

    # The stored shape: business fields under "data", as replayed.
    enveloped =
      BookclubState.apply_event(BookclubState.new("bookclub-2"), %{
        event_type: "bookclub_initiated_v1",
        data: %{name: "Enveloped"}
      })

    assert BookclubState.initiated?(enveloped)
    assert enveloped.name == "Enveloped"
  end
end

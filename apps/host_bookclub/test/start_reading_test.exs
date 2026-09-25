defmodule HostBookclub.StartReadingTest do
  # The start_reading slice: the command, the self-contained event, the
  # state fold, the desk rule and the aggregate's blanket guard. Pure, no
  # store.
  use ExUnit.Case, async: true

  alias HostBookclub.ReadingAggregate
  alias HostBookclub.ReadingState
  alias HostBookclub.StartReading.{MaybeStartReading, ReadingStartedV1, StartReadingV1}

  defp reading_id, do: "reading-#{String.duplicate("a", 32)}"
  defp member_id, do: "member-#{String.duplicate("b", 32)}"
  defp book_id, do: "book-#{String.duplicate("c", 32)}"

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             StartReadingV1.new(%{reading_id: reading_id(), member_id: member_id()})

    assert {:error, :invalid_params} =
             StartReadingV1.new(%{reading_id: reading_id(), member_id: "", book_id: book_id()})
  end

  test "a minted reading id satisfies the stream contract" do
    minted = StartReadingV1.mint_reading_id()
    assert :ok = :reckon_gater_stream_id.validate(minted)

    {:ok, cmd} =
      StartReadingV1.new(%{reading_id: minted, member_id: member_id(), book_id: book_id()})

    assert :ok = StartReadingV1.validate(cmd)
  end

  test "the event is a self-contained fact" do
    {:ok, event} =
      ReadingStartedV1.new(%{
        reading_id: reading_id(),
        member_id: member_id(),
        book_id: book_id()
      })

    map = ReadingStartedV1.to_map(event)
    assert map.event_type == "reading_started_v1"
    assert map.member_id == member_id()
    assert map.book_id == book_id()
    assert is_integer(map.started_at)
  end

  test "the state folds both event shapes" do
    state = ReadingState.new(reading_id())
    refute ReadingState.in_progress?(state)

    raw =
      ReadingState.apply_event(state, %{
        event_type: "reading_started_v1",
        member_id: member_id(),
        book_id: book_id()
      })

    assert ReadingState.in_progress?(raw)
    assert raw.book_id == book_id()

    enveloped =
      ReadingState.apply_event(ReadingState.new(reading_id()), %{
        event_type: "reading_started_v1",
        data: %{member_id: member_id(), book_id: book_id()}
      })

    assert ReadingState.in_progress?(enveloped)
  end

  test "the desk refuses a second start" do
    {:ok, cmd} =
      StartReadingV1.new(%{reading_id: reading_id(), member_id: member_id(), book_id: book_id()})

    in_progress =
      ReadingState.apply_event(ReadingState.new(reading_id()), %{
        event_type: "reading_started_v1",
        member_id: member_id(),
        book_id: book_id()
      })

    assert {:error, :already_started} = MaybeStartReading.handle(in_progress, cmd)
  end

  test "the aggregate's blanket guard refuses every command on a finished reading" do
    finished =
      ReadingState.apply_event(ReadingState.new(reading_id()), %{
        event_type: "reading_started_v1",
        member_id: member_id(),
        book_id: book_id()
      })
      |> ReadingState.apply_event(%{event_type: "reading_finished_v1", pages_read: 12})

    assert {:error, :finished} =
             ReadingAggregate.execute(finished, %{
               command_type: :finish_reading_v1,
               reading_id: reading_id(),
               pages_read: 12
             })
  end
end

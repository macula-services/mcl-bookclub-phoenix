defmodule HostBookclub.FinishReadingTest do
  # The finish_reading slice: the command, the self-contained event and
  # the state fold. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.FinishReading.{FinishReadingV1, MaybeFinishReading, ReadingFinishedV1}
  alias HostBookclub.ReadingState

  defp reading_id, do: "reading-#{String.duplicate("a", 32)}"
  defp member_id, do: "member-#{String.duplicate("b", 32)}"
  defp book_id, do: "book-#{String.duplicate("c", 32)}"

  defp in_progress_state do
    ReadingState.apply_event(ReadingState.new(reading_id()), %{
      event_type: "reading_started_v1",
      member_id: member_id(),
      book_id: book_id(),
      started_at: 42
    })
  end

  test "a command needs a reading id and non-negative pages" do
    assert {:error, :missing_required_fields} = FinishReadingV1.new(%{reading_id: reading_id()})

    assert {:error, :invalid_params} =
             FinishReadingV1.new(%{reading_id: reading_id(), pages_read: -1})

    assert {:error, :invalid_params} =
             FinishReadingV1.new(%{reading_id: reading_id(), pages_read: "12"})
  end

  test "the event echoes the reading's birth details" do
    {:ok, event} =
      ReadingFinishedV1.new(%{
        reading_id: reading_id(),
        member_id: member_id(),
        book_id: book_id(),
        started_at: 42,
        pages_read: 120
      })

    map = ReadingFinishedV1.to_map(event)
    assert map.event_type == "reading_finished_v1"
    assert map.member_id == member_id()
    assert map.book_id == book_id()
    assert map.started_at == 42
    assert map.pages_read == 120
    assert is_integer(map.finished_at)
  end

  test "the state folds the finished bit and the pages from both event shapes" do
    raw =
      ReadingState.apply_event(in_progress_state(), %{
        event_type: "reading_finished_v1",
        pages_read: 120
      })

    assert ReadingState.finished?(raw)
    assert raw.pages_read == 120

    enveloped =
      ReadingState.apply_event(in_progress_state(), %{
        event_type: "reading_finished_v1",
        data: %{pages_read: 99}
      })

    assert ReadingState.finished?(enveloped)
    assert enveloped.pages_read == 99
  end

  test "the desk refuses to finish a reading that never started" do
    {:ok, cmd} = FinishReadingV1.new(%{reading_id: reading_id(), pages_read: 120})
    assert {:error, :not_started} = MaybeFinishReading.handle(ReadingState.new(reading_id()), cmd)
  end
end

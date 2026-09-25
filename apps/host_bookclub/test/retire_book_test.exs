defmodule HostBookclub.RetireBookTest do
  # The retire_book slice: the command, the self-contained event, the
  # state fold and the desk rule. Pure, no store.
  use ExUnit.Case, async: true

  alias HostBookclub.BookState
  alias HostBookclub.RetireBook.{BookRetiredV1, MaybeRetireBook, RetireBookV1}

  defp book_id, do: "book-#{String.duplicate("a", 32)}"
  defp club_id, do: "bookclub-#{String.duplicate("b", 32)}"

  defp on_shelf_state do
    BookState.apply_event(BookState.new(book_id()), %{
      event_type: "book_procured_v1",
      club_id: club_id(),
      title: "Emma",
      author: "Austen",
      procured_at: 42,
      club_name: "The Crooked Shelf"
    })
  end

  test "a command needs every field" do
    assert {:error, :missing_required_fields} = RetireBookV1.new(%{book_id: book_id()})
    assert {:error, :invalid_params} = RetireBookV1.new(%{book_id: book_id(), retired_by: ""})
  end

  test "the event echoes the bibliographic facts" do
    {:ok, event} =
      BookRetiredV1.new(%{
        book_id: book_id(),
        club_id: club_id(),
        title: "Emma",
        author: "Austen",
        procured_at: 42,
        club_name: "The Crooked Shelf",
        retired_by: "raf"
      })

    map = BookRetiredV1.to_map(event)
    assert map.event_type == "book_retired_v1"
    assert map.title == "Emma"
    assert map.author == "Austen"
    assert map.procured_at == 42
    assert map.club_name == "The Crooked Shelf"
    assert map.retired_by == "raf"
    assert is_integer(map.retired_at)
  end

  test "the state folds the retired bit from both event shapes" do
    raw = BookState.apply_event(on_shelf_state(), %{event_type: "book_retired_v1"})
    assert BookState.retired?(raw)

    enveloped =
      BookState.apply_event(on_shelf_state(), %{
        event_type: "book_retired_v1",
        data: %{retired_by: "raf"}
      })

    assert BookState.retired?(enveloped)
  end

  test "the desk refuses to retire a book that was never procured" do
    {:ok, cmd} = RetireBookV1.new(%{book_id: book_id(), retired_by: "raf"})
    assert {:error, :not_procured} = MaybeRetireBook.handle(BookState.new(book_id()), cmd)
  end
end

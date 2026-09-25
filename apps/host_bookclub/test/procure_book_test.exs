defmodule HostBookclub.ProcureBookTest do
  # The procure_book slice: the command, the self-contained event, the
  # state fold, the desk rule and the aggregate's blanket guard. Pure, no
  # store.
  use ExUnit.Case, async: true

  alias HostBookclub.BookAggregate
  alias HostBookclub.BookState
  alias HostBookclub.ProcureBook.{BookProcuredV1, MaybeProcureBook, ProcureBookV1}

  defp book_id, do: "book-#{String.duplicate("a", 32)}"
  defp club_id, do: "bookclub-#{String.duplicate("b", 32)}"

  test "a command needs every field" do
    assert {:error, :missing_required_fields} =
             ProcureBookV1.new(%{book_id: book_id(), club_id: club_id(), title: "Emma"})

    assert {:error, :invalid_params} =
             ProcureBookV1.new(%{
               book_id: book_id(),
               club_id: club_id(),
               title: "",
               author: "Austen"
             })
  end

  test "a minted book id satisfies the stream contract" do
    minted = ProcureBookV1.mint_book_id()
    assert :ok = :reckon_gater_stream_id.validate(minted)

    {:ok, cmd} =
      ProcureBookV1.new(%{book_id: minted, club_id: club_id(), title: "Emma", author: "Austen"})

    assert :ok = ProcureBookV1.validate(cmd)
  end

  test "the club_name rides along, defaulting to empty" do
    {:ok, cmd} =
      ProcureBookV1.new(%{
        book_id: book_id(),
        club_id: club_id(),
        title: "Emma",
        author: "Austen"
      })

    assert cmd.club_name == ""
  end

  test "the event is a self-contained fact" do
    {:ok, event} =
      BookProcuredV1.new(%{
        book_id: book_id(),
        club_id: club_id(),
        title: "Emma",
        author: "Austen",
        club_name: "The Crooked Shelf"
      })

    map = BookProcuredV1.to_map(event)
    assert map.event_type == "book_procured_v1"
    assert map.club_name == "The Crooked Shelf"
    assert map.title == "Emma"
    assert is_integer(map.procured_at)
  end

  test "the state folds both event shapes" do
    state = BookState.new(book_id())
    refute BookState.on_shelf?(state)

    raw =
      BookState.apply_event(state, %{
        event_type: "book_procured_v1",
        club_id: club_id(),
        title: "Emma",
        author: "Austen"
      })

    assert BookState.on_shelf?(raw)
    assert raw.title == "Emma"

    enveloped =
      BookState.apply_event(BookState.new(book_id()), %{
        event_type: "book_procured_v1",
        data: %{club_id: club_id(), title: "Enveloped", author: "Austen"}
      })

    assert BookState.on_shelf?(enveloped)
    assert enveloped.title == "Enveloped"
  end

  test "the desk refuses a second procurement" do
    {:ok, cmd} =
      ProcureBookV1.new(%{
        book_id: book_id(),
        club_id: club_id(),
        title: "Emma",
        author: "Austen"
      })

    on_shelf =
      BookState.apply_event(BookState.new(book_id()), %{
        event_type: "book_procured_v1",
        club_id: club_id(),
        title: "Emma",
        author: "Austen"
      })

    assert {:error, :already_procured} = MaybeProcureBook.handle(on_shelf, cmd)
  end

  test "the aggregate's blanket guard refuses every command on a retired book" do
    retired =
      BookState.apply_event(BookState.new(book_id()), %{
        event_type: "book_procured_v1",
        club_id: club_id(),
        title: "Emma",
        author: "Austen"
      })
      |> BookState.apply_event(%{event_type: "book_retired_v1"})

    assert {:error, :retired} =
             BookAggregate.execute(retired, %{command_type: :retire_book_v1, book_id: book_id()})
  end
end

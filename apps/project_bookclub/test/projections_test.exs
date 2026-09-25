defmodule ProjectBookclub.ProjectionsTest do
  # Each projection, end to end at the sqlite + pubsub seam: the store
  # process is the one the test boot started, the broadcast is asserted
  # with a live subscription -- the exact pair the LiveView admin relies
  # on. No evoq involved: the events are fabricated in the raw shape
  # (business fields inline) the projections read tolerantly.
  use ExUnit.Case, async: false

  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  alias ProjectBookclub.BookclubArchived.BookclubArchivedV1ToSqliteClubs
  alias ProjectBookclub.BookclubInitiated.BookclubInitiatedV1ToSqliteClubs
  alias ProjectBookclub.BookProcured.BookProcuredV1ToSqliteBooks
  alias ProjectBookclub.BookRetired.BookRetiredV1ToSqliteBooks
  alias ProjectBookclub.MemberRegistered.MemberRegisteredV1ToSqliteMembers
  alias ProjectBookclub.MemberUnregistered.MemberUnregisteredV1ToSqliteMembers
  alias ProjectBookclub.ReadingFinished.ReadingFinishedV1ToSqliteReadings
  alias ProjectBookclub.ReadingStarted.ReadingStartedV1ToSqliteReadings

  @projections [
    BookclubInitiatedV1ToSqliteClubs,
    BookclubArchivedV1ToSqliteClubs,
    MemberRegisteredV1ToSqliteMembers,
    MemberUnregisteredV1ToSqliteMembers,
    BookProcuredV1ToSqliteBooks,
    BookRetiredV1ToSqliteBooks,
    ReadingStartedV1ToSqliteReadings,
    ReadingFinishedV1ToSqliteReadings
  ]

  # Ids use their own per-file suffixes ("p"/"q"/"r"/"s") so no write in
  # this file can collide with the query desks' seeded rows -- the whole
  # suite shares one sqlite file, and a plain INSERT against an existing
  # PRIMARY KEY fails silently instead of overriding.
  defp club_id, do: "bookclub-#{String.duplicate("p", 32)}"
  defp member_id, do: "member-#{String.duplicate("q", 32)}"
  defp book_id, do: "book-#{String.duplicate("r", 32)}"
  defp reading_id, do: "reading-#{String.duplicate("s", 32)}"

  # The schema the test boot created is the PRJ division's own: the query
  # desks' tests pin their SELECTs to it, these tests pin the writes.
  test "every projection is replay-deliverable" do
    # The writes are INSERT OR REPLACE keyed on the stream id -- applying
    # an event twice is the same write twice, so a replay must re-apply,
    # not skip.
    for projection <- @projections do
      assert projection.replay_policy() == :deliver, inspect(projection)
    end
  end

  test "the initiated projection writes the clubs row and broadcasts" do
    club_id = club_id()
    subscribe()

    event = %{
      event_type: "bookclub_initiated_v1",
      club_id: club_id,
      name: "The Crooked Shelf",
      initiated_by: "bea",
      initiated_at: 42,
      event_id: "evt-1",
      version: 0
    }

    assert {:ok, %{}} =
             BookclubInitiatedV1ToSqliteClubs.handle_event(
               "bookclub_initiated_v1",
               event,
               %{},
               %{}
             )

    assert [[^club_id, "The Crooked Shelf", "active", "bea", 42, "evt-1", 0]] =
             BookclubReadModelStore.q(
               "SELECT club_id, name, status, initiated_by, initiated_at, event_id, version" <>
                 " FROM clubs WHERE club_id = ?",
               [club_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :clubs, event_type: "bookclub_initiated_v1", id: ^club_id}}
  end

  test "the archived projection is self-sufficient and overwrites the row" do
    club_id = club_id()
    subscribe()

    # The archived event arrives with NO initiated event having preceded
    # it -- the write must still rebuild the whole row.
    event = %{
      event_type: "bookclub_archived_v1",
      club_id: club_id,
      name: "The Crooked Shelf",
      initiated_by: "bea",
      initiated_at: 42,
      archived_by: "raf",
      event_id: "evt-2",
      version: 1
    }

    assert {:ok, %{}} =
             BookclubArchivedV1ToSqliteClubs.handle_event("bookclub_archived_v1", event, %{}, %{})

    assert [[^club_id, "The Crooked Shelf", "archived", "bea", 42, "evt-2", 1]] =
             BookclubReadModelStore.q(
               "SELECT club_id, name, status, initiated_by, initiated_at, event_id, version" <>
                 " FROM clubs WHERE club_id = ?",
               [club_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :clubs, event_type: "bookclub_archived_v1", id: ^club_id}}
  end

  test "the member projections write the members row, both statuses" do
    club_id = club_id()
    member_id = member_id()
    subscribe()

    registered = %{
      event_type: "member_registered_v1",
      member_id: member_id,
      club_id: club_id,
      name: "Bea",
      registered_at: 42,
      event_id: "evt-1",
      version: 0
    }

    assert {:ok, %{}} =
             MemberRegisteredV1ToSqliteMembers.handle_event(
               "member_registered_v1",
               registered,
               %{},
               %{}
             )

    assert [[^member_id, "active"]] =
             BookclubReadModelStore.q(
               "SELECT member_id, status FROM members WHERE member_id = ?",
               [member_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :members, event_type: "member_registered_v1", id: ^member_id}}

    unregistered = %{
      event_type: "member_unregistered_v1",
      member_id: member_id,
      club_id: club_id,
      name: "Bea",
      registered_at: 42,
      event_id: "evt-2",
      version: 1
    }

    assert {:ok, %{}} =
             MemberUnregisteredV1ToSqliteMembers.handle_event(
               "member_unregistered_v1",
               unregistered,
               %{},
               %{}
             )

    assert [[^member_id, "unregistered"]] =
             BookclubReadModelStore.q(
               "SELECT member_id, status FROM members WHERE member_id = ?",
               [member_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :members, event_type: "member_unregistered_v1", id: ^member_id}}
  end

  test "the book projections write the books row, both statuses" do
    club_id = club_id()
    book_id = book_id()
    subscribe()

    procured = %{
      event_type: "book_procured_v1",
      book_id: book_id,
      club_id: club_id,
      title: "Emma",
      author: "Austen",
      procured_at: 42,
      event_id: "evt-1",
      version: 0
    }

    assert {:ok, %{}} =
             BookProcuredV1ToSqliteBooks.handle_event("book_procured_v1", procured, %{}, %{})

    assert [[^book_id, "Emma", "Austen", "on_shelf", 42]] =
             BookclubReadModelStore.q(
               "SELECT book_id, title, author, status, procured_at FROM books WHERE book_id = ?",
               [book_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :books, event_type: "book_procured_v1", id: ^book_id}}

    retired = %{
      event_type: "book_retired_v1",
      book_id: book_id,
      club_id: club_id,
      title: "Emma",
      author: "Austen",
      procured_at: 42,
      event_id: "evt-2",
      version: 1
    }

    assert {:ok, %{}} =
             BookRetiredV1ToSqliteBooks.handle_event("book_retired_v1", retired, %{}, %{})

    assert [[^book_id, "retired"]] =
             BookclubReadModelStore.q(
               "SELECT book_id, status FROM books WHERE book_id = ?",
               [book_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :books, event_type: "book_retired_v1", id: ^book_id}}
  end

  test "the reading projections fold start then finish into one row" do
    member_id = member_id()
    book_id = book_id()
    reading_id = reading_id()
    subscribe()

    started = %{
      event_type: "reading_started_v1",
      reading_id: reading_id,
      member_id: member_id,
      book_id: book_id,
      started_at: 42,
      event_id: "evt-1",
      version: 0
    }

    assert {:ok, %{}} =
             ReadingStartedV1ToSqliteReadings.handle_event(
               "reading_started_v1",
               started,
               %{},
               %{}
             )

    # esqlite maps SQL NULL to the Erlang atom `undefined' (the Elixir
    # `:undefined'), NOT to nil -- the Elixir side of the workspace's
    # pinned gotcha.
    assert [[^reading_id, "in_progress", 0, :undefined]] =
             BookclubReadModelStore.q(
               "SELECT reading_id, status, pages_read, finished_at FROM readings" <>
                 " WHERE reading_id = ?",
               [reading_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :readings, event_type: "reading_started_v1", id: ^reading_id}}

    finished = %{
      event_type: "reading_finished_v1",
      reading_id: reading_id,
      member_id: member_id,
      book_id: book_id,
      started_at: 42,
      pages_read: 120,
      finished_at: 43,
      event_id: "evt-2",
      version: 1
    }

    assert {:ok, %{}} =
             ReadingFinishedV1ToSqliteReadings.handle_event(
               "reading_finished_v1",
               finished,
               %{},
               %{}
             )

    assert [[^reading_id, "finished", 120, 43]] =
             BookclubReadModelStore.q(
               "SELECT reading_id, status, pages_read, finished_at FROM readings" <>
                 " WHERE reading_id = ?",
               [reading_id]
             )

    assert_received {:bookclub_changed,
                     %{table: :readings, event_type: "reading_finished_v1", id: ^reading_id}}
  end

  defp subscribe do
    :ok = Phoenix.PubSub.subscribe(MclBookclubPhoenixWeb.PubSub, BookclubChanged.topic())
  end
end

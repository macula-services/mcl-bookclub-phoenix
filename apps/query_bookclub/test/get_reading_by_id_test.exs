defmodule QueryBookclub.GetReadingByIdTest do
  # get_reading_by_id against a seeded sqlite read model -- the test
  # stands in for the PRJ division having run.
  use ExUnit.Case

  alias QueryBookclub.GetReadingById.GetReadingById

  setup do
    dir = System.get_env("MCL_DATA_DIR")
    File.mkdir_p!(dir)

    # The readings table, from the PRJ division's own definition -- the
    # test does not invent a schema of its own.
    schema = [
      "CREATE TABLE IF NOT EXISTS readings (" <>
        " reading_id TEXT PRIMARY KEY, member_id TEXT NOT NULL, book_id TEXT NOT NULL," <>
        " status TEXT NOT NULL, started_at INTEGER NOT NULL, pages_read INTEGER NOT NULL," <>
        " finished_at INTEGER, event_id TEXT NOT NULL, version INTEGER NOT NULL)"
    ]

    {:ok, conn} = :esqlite3.open(String.to_charlist(Path.join(dir, "bookclub.sqlite3")))
    for sql <- schema, do: :ok = :esqlite3.exec(conn, sql)

    %{conn: conn}
  end

  test "a finished reading is found with its pages and finish time", %{conn: conn} do
    # Ids use this file's own suffixes ("k"/"l"/"m") so no other suite's
    # seeded row can sit under the same PRIMARY KEY.
    reading_id = "reading-#{String.duplicate("k", 32)}"
    member_id = "member-#{String.duplicate("l", 32)}"
    book_id = "book-#{String.duplicate("m", 32)}"

    :esqlite3.q(
      conn,
      "INSERT INTO readings VALUES (?, ?, ?, 'finished', ?, ?, ?, ?, ?)",
      [reading_id, member_id, book_id, 42, 120, 43, "evt-1", 1]
    )

    assert {:ok, reading} = GetReadingById.find(reading_id)
    assert reading.status == "finished"
    assert reading.pages_read == 120
    assert reading.finished_at == 43
  end

  test "an in-progress reading has no finish time", %{conn: conn} do
    reading_id = "reading-#{String.duplicate("n", 32)}"
    member_id = "member-#{String.duplicate("o", 32)}"
    book_id = "book-#{String.duplicate("v", 32)}"

    :esqlite3.q(conn, "INSERT INTO readings VALUES (?, ?, ?, 'in_progress', ?, 0, NULL, ?, ?)", [
      reading_id,
      member_id,
      book_id,
      42,
      "evt-1",
      0
    ])

    # SQL NULL comes back as the Erlang atom `undefined' (`:undefined'),
    # not nil -- the Elixir side of the workspace's pinned gotcha.
    assert {:ok, %{finished_at: :undefined}} = GetReadingById.find(reading_id)
  end

  test "an unknown reading is not found" do
    assert {:error, :not_found} = GetReadingById.find("reading-#{String.duplicate("w", 32)}")
  end
end

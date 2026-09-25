defmodule QueryBookclub.GetReadingsByMemberTest do
  # get_readings_by_member against a seeded sqlite read model -- the test
  # stands in for the PRJ division having run.
  use ExUnit.Case

  alias QueryBookclub.GetReadingsByMember.GetReadingsByMember

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

  test "one member's readings come back oldest first", %{conn: conn} do
    # Ids use this file's own suffixes ("x"/"y"/"z") so no other suite's
    # seeded row can sit under the same PRIMARY KEY.
    member_id = "member-#{String.duplicate("x", 32)}"
    book_id = "book-#{String.duplicate("x", 32)}"

    :esqlite3.q(conn, "INSERT INTO readings VALUES (?, ?, ?, 'finished', ?, ?, ?, ?, ?)", [
      "reading-#{String.duplicate("y", 32)}",
      member_id,
      book_id,
      200,
      10,
      201,
      "evt-1",
      1
    ])

    :esqlite3.q(conn, "INSERT INTO readings VALUES (?, ?, ?, 'in_progress', ?, 0, NULL, ?, ?)", [
      "reading-#{String.duplicate("z", 32)}",
      member_id,
      book_id,
      100,
      "evt-2",
      0
    ])

    assert {:ok, readings} = GetReadingsByMember.find(member_id)
    assert [first, second] = readings
    assert first.started_at == 100
    assert second.started_at == 200
  end

  test "a member with no readings gets an empty list" do
    assert {:ok, []} = GetReadingsByMember.find("member-#{String.duplicate("t", 32)}")
  end
end

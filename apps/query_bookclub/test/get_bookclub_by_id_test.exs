defmodule QueryBookclub.GetBookclubByIdTest do
  # get_bookclub_by_id against a seeded sqlite read model -- the test
  # stands in for the PRJ division having run.
  use ExUnit.Case

  alias QueryBookclub.BookclubQueryStore
  alias QueryBookclub.GetBookclubById.GetBookclubById

  setup do
    dir = System.get_env("MCL_DATA_DIR")
    File.mkdir_p!(dir)

    # The store is provided by the app's own supervision tree (mix test
    # boots the application); the test seeds through its own connection.

    # The schema, from the PRJ division's own definition -- the test does
    # not duplicate it.
    schema = [
      "CREATE TABLE IF NOT EXISTS clubs (" <>
        " club_id TEXT PRIMARY KEY, name TEXT NOT NULL, status TEXT NOT NULL," <>
        " initiated_by TEXT NOT NULL, initiated_at INTEGER NOT NULL," <>
        " event_id TEXT NOT NULL, version INTEGER NOT NULL)"
    ]

    {:ok, conn} = :esqlite3.open(String.to_charlist(Path.join(dir, "bookclub.sqlite3")))
    for sql <- schema, do: :ok = :esqlite3.exec(conn, sql)

    %{conn: conn}
  end

  test "a known club is found", %{conn: conn} do
    club_id = "bookclub-#{String.duplicate("a", 32)}"

    :esqlite3.q(conn, "INSERT INTO clubs VALUES (?, ?, 'active', ?, ?, ?, ?)", [
      club_id, "The Crooked Shelf", "raf", 42, "evt-1", 0
    ])

    assert {:ok, club} = GetBookclubById.find(club_id)
    assert club.name == "The Crooked Shelf"
    assert club.status == "active"
  end

  test "an unknown club is not found" do
    assert {:error, :not_found} = GetBookclubById.find("bookclub-#{String.duplicate("b", 32)}")
  end
end

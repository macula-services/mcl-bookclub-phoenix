defmodule QueryBookclub.GetBookByIdTest do
  # get_book_by_id against a seeded sqlite read model -- the test stands
  # in for the PRJ division having run.
  use ExUnit.Case

  alias QueryBookclub.GetBookById.GetBookById

  setup do
    dir = System.get_env("MCL_DATA_DIR")
    File.mkdir_p!(dir)

    # The books table, from the PRJ division's own definition -- the test
    # does not invent a schema of its own.
    schema = [
      "CREATE TABLE IF NOT EXISTS books (" <>
        " book_id TEXT PRIMARY KEY, club_id TEXT NOT NULL, title TEXT NOT NULL," <>
        " author TEXT NOT NULL, status TEXT NOT NULL, procured_at INTEGER NOT NULL," <>
        " event_id TEXT NOT NULL, version INTEGER NOT NULL)"
    ]

    {:ok, conn} = :esqlite3.open(String.to_charlist(Path.join(dir, "bookclub.sqlite3")))
    for sql <- schema, do: :ok = :esqlite3.exec(conn, sql)

    %{conn: conn}
  end

  test "a known book is found, retired or not", %{conn: conn} do
    # Ids use this file's own suffix ("g") so no other suite's seeded row
    # can sit under the same PRIMARY KEY.
    book_id = "book-#{String.duplicate("g", 32)}"
    club_id = "bookclub-#{String.duplicate("g", 32)}"

    :esqlite3.q(conn, "INSERT INTO books VALUES (?, ?, ?, ?, 'retired', ?, ?, ?)", [
      book_id,
      club_id,
      "Emma",
      "Austen",
      42,
      "evt-1",
      0
    ])

    assert {:ok, book} = GetBookById.find(book_id)
    assert book.title == "Emma"
    assert book.status == "retired"
  end

  test "an unknown book is not found" do
    assert {:error, :not_found} = GetBookById.find("book-#{String.duplicate("h", 32)}")
  end
end

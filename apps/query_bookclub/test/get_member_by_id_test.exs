defmodule QueryBookclub.GetMemberByIdTest do
  # get_member_by_id against a seeded sqlite read model -- the test stands
  # in for the PRJ division having run.
  use ExUnit.Case

  alias QueryBookclub.GetMemberById.GetMemberById

  setup do
    dir = System.get_env("MCL_DATA_DIR")
    File.mkdir_p!(dir)

    # The members table, from the PRJ division's own definition -- the
    # test does not invent a schema of its own.
    schema = [
      "CREATE TABLE IF NOT EXISTS members (" <>
        " member_id TEXT PRIMARY KEY, club_id TEXT NOT NULL, name TEXT NOT NULL," <>
        " status TEXT NOT NULL, registered_at INTEGER NOT NULL," <>
        " event_id TEXT NOT NULL, version INTEGER NOT NULL)"
    ]

    {:ok, conn} = :esqlite3.open(String.to_charlist(Path.join(dir, "bookclub.sqlite3")))
    for sql <- schema, do: :ok = :esqlite3.exec(conn, sql)

    %{conn: conn}
  end

  test "a known member is found, unregistered or not", %{conn: conn} do
    # Ids use this file's own suffix ("i") so no other suite's seeded row
    # can sit under the same PRIMARY KEY.
    member_id = "member-#{String.duplicate("i", 32)}"
    club_id = "bookclub-#{String.duplicate("i", 32)}"

    :esqlite3.q(conn, "INSERT INTO members VALUES (?, ?, ?, 'unregistered', ?, ?, ?)", [
      member_id,
      club_id,
      "Bea",
      42,
      "evt-1",
      0
    ])

    assert {:ok, member} = GetMemberById.find(member_id)
    assert member.name == "Bea"
    assert member.status == "unregistered"
  end

  test "an unknown member is not found" do
    assert {:error, :not_found} = GetMemberById.find("member-#{String.duplicate("j", 32)}")
  end
end

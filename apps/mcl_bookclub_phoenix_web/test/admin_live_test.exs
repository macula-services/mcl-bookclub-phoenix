defmodule MclBookclubPhoenixWeb.AdminLiveTest do
  # The admin console's pure half: the task table mirrors the Erlang
  # admin's own, and the paths that fail BEFORE any dispatch do so
  # without the store -- including the validate-before-dispatch boundary
  # (Demon 67): a bad stream id is refused by the desk, and that refusal
  # is what the operator sees. No store, no socket.
  use ExUnit.Case, async: true

  alias MclBookclubPhoenixWeb.AdminLive

  test "the task table has the Erlang admin's nine tasks, one per command" do
    ids = Enum.map(AdminLive.tasks(), & &1.id)

    assert ids == [
             "initiate",
             "plan_party",
             "archive",
             "register",
             "unregister",
             "procure",
             "retire",
             "start",
             "finish"
           ]
  end

  test "every task carries a label and at least one field" do
    for task <- AdminLive.tasks() do
      assert is_binary(task.label) and task.label != ""
      assert is_list(task.fields) and task.fields != []
    end
  end

  test "an unknown task is refused" do
    assert {:error, {:unknown_task, "bogus"}} = AdminLive.run_task("bogus", %{})
  end

  test "a non-integer page count is refused before any dispatch" do
    assert {:error, :invalid_pages} = AdminLive.run_task("finish", %{"pages_read" => "lots"})
  end

  test "a bad stream id is refused at the validate boundary, never the store" do
    assert {:error, _} = AdminLive.run_task("plan_party", %{"club_id" => "not-a-stream-id"})
    assert {:error, _} = AdminLive.run_task("archive", %{"club_id" => "not-a-stream-id"})
    assert {:error, _} = AdminLive.run_task("retire", %{"book_id" => "not-a-stream-id"})

    assert {:error, _} =
             AdminLive.run_task("finish", %{
               "reading_id" => "not-a-stream-id",
               "pages_read" => "12"
             })

    assert {:error, _} =
             AdminLive.run_task("start", %{"member_id" => "not-a-stream-id", "book_id" => "b"})
  end

  test "a task with missing required fields is refused" do
    assert {:error, :invalid_params} =
             AdminLive.run_task("initiate", %{"name" => "", "initiated_by" => "raf"})

    assert {:error, :invalid_params} =
             AdminLive.run_task("archive", %{"club_id" => "club", "archived_by" => ""})
  end

  test "the lookup kinds cover the five reads the Erlang admin offers" do
    kinds = Enum.map(AdminLive.lookup_kinds(), &elem(&1, 0))

    assert kinds == ["club", "member", "book", "reading", "readings_by_member"]
  end
end

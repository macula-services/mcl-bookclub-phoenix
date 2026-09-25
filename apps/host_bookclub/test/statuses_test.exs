defmodule HostBookclub.StatusesTest do
  # The status modules: the flag maps and their readable names.
  #
  # These tests pin the read-model contract's status strings to the flag
  # maps that own them. The projections derive their status strings from
  # these modules (never from literals of their own -- see the PRJ
  # boundary test), so a change here is a deliberate, visible change to
  # the strings every query desk hands out.
  use ExUnit.Case, async: true

  alias HostBookclub.{BookclubStatus, BookStatus, MemberStatus, ReadingStatus}

  test "the bookclub flag map names the two flags" do
    assert BookclubStatus.labels() == %{1 => "active", 2 => "archived"}
  end

  test "the book flag map names the two flags" do
    assert BookStatus.labels() == %{1 => "on_shelf", 2 => "retired"}
  end

  test "the member flag map names the two flags" do
    assert MemberStatus.labels() == %{1 => "active", 2 => "unregistered"}
  end

  test "the reading flag map names the two flags" do
    assert ReadingStatus.labels() == %{1 => "in_progress", 2 => "finished"}
  end

  test "to_string renders a mask through evoq's own conversion" do
    # A single flag renders its own name; a mask of both renders the
    # joined description evoq's conversion produces.
    assert BookclubStatus.to_string(BookclubStatus.initiated()) == "active"
    assert BookclubStatus.to_string(BookclubStatus.archived()) == "archived"

    assert BookclubStatus.to_string(
             Bitwise.bor(BookclubStatus.initiated(), BookclubStatus.archived())
           ) == "active, archived"
  end
end

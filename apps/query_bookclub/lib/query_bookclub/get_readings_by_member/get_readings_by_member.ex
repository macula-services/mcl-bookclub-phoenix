defmodule QueryBookclub.GetReadingsByMember.GetReadingsByMember do
  # get_readings_by_member: the readings of one member, oldest first.
  #
  # The field-query pattern (get_{aggregates}_by_{field}), deliberately not
  # a paged list: a member's reading history is small and ordered, and the
  # paged pattern arrives with the list desks. The clause is here, not
  # hidden in a shared helper.
  @moduledoc false

  alias QueryBookclub.BookclubQueryStore

  def find(member_id) when is_binary(member_id) do
    found(
      BookclubQueryStore.q(
        "SELECT reading_id, member_id, book_id, status, started_at," <>
          " pages_read, finished_at FROM readings" <>
          " WHERE member_id = ? ORDER BY started_at",
        [member_id]
      )
    )
  end

  def find(_), do: {:error, :missing_member_id}

  defp found(rows) when is_list(rows) do
    {:ok, Enum.map(rows, &to_map/1)}
  end

  defp found({:error, reason}), do: {:error, {:store_error, reason}}

  defp to_map([reading_id, member_id, book_id, status, started_at, pages, finished_at]) do
    %{
      reading_id: reading_id,
      member_id: member_id,
      book_id: book_id,
      status: status,
      started_at: started_at,
      pages_read: pages,
      finished_at: finished_at
    }
  end
end

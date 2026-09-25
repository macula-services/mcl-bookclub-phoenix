defmodule QueryBookclub.GetReadingById.GetReadingById do
  # get_reading_by_id: the reading, by its stream id.
  #
  # A query module is a pure module answered by the query store: no state,
  # no framework, no mesh.
  @moduledoc false

  alias QueryBookclub.BookclubQueryStore

  def find(reading_id) when is_binary(reading_id) do
    found(
      BookclubQueryStore.q(
        "SELECT reading_id, member_id, book_id, status, started_at," <>
          " pages_read, finished_at FROM readings WHERE reading_id = ?",
        [reading_id]
      )
    )
  end

  def find(_), do: {:error, :missing_reading_id}

  defp found([[reading_id, member_id, book_id, status, started_at, pages, finished_at] | _]) do
    {:ok,
     %{
       reading_id: reading_id,
       member_id: member_id,
       book_id: book_id,
       status: status,
       started_at: started_at,
       pages_read: pages,
       finished_at: finished_at
     }}
  end

  defp found([]), do: {:error, :not_found}
  defp found({:error, reason}), do: {:error, {:store_error, reason}}
end

defmodule QueryBookclub.GetBookById.GetBookById do
  # get_book_by_id: the book, by its stream id.
  #
  # A query module is a pure module answered by the query store: no state,
  # no framework, no mesh. A retired book is still answerable by id, with
  # its status visible. Banned-name clean: get_{aggregate}_by_id.
  @moduledoc false

  alias QueryBookclub.BookclubQueryStore

  def find(book_id) when is_binary(book_id) do
    found(
      BookclubQueryStore.q(
        "SELECT book_id, club_id, title, author, status, procured_at FROM books WHERE book_id = ?",
        [book_id]
      )
    )
  end

  def find(_), do: {:error, :missing_book_id}

  defp found([[book_id, club_id, title, author, status, at] | _]) do
    {:ok,
     %{
       book_id: book_id,
       club_id: club_id,
       title: title,
       author: author,
       status: status,
       procured_at: at
     }}
  end

  defp found([]), do: {:error, :not_found}
  defp found({:error, reason}), do: {:error, {:store_error, reason}}
end

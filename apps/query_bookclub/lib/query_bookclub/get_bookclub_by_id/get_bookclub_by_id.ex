defmodule QueryBookclub.GetBookclubById.GetBookclubById do
  # get_bookclub_by_id: the club, by its stream id.
  #
  # A query module is a pure module answered by the query store: no state,
  # no framework, no mesh. Banned-name clean: get_{aggregate}_by_id.
  @moduledoc false

  alias QueryBookclub.BookclubQueryStore

  def find(club_id) when is_binary(club_id) do
    found(
      BookclubQueryStore.q(
        "SELECT club_id, name, status, initiated_by, initiated_at FROM clubs WHERE club_id = ?",
        [club_id]
      )
    )
  end

  def find(_), do: {:error, :missing_club_id}

  defp found([[club_id, name, status, by, at] | _]) do
    {:ok,
     %{club_id: club_id, name: name, status: status, initiated_by: by,
       initiated_at: at}}
  end

  defp found([]), do: {:error, :not_found}
  defp found({:error, reason}), do: {:error, {:store_error, reason}}
end

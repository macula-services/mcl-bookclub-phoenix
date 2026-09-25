defmodule QueryBookclub.GetMemberById.GetMemberById do
  # get_member_by_id: the member, by its stream id.
  #
  # A query module is a pure module answered by the query store: no state,
  # no framework, no mesh. An unregistered member is still answerable by
  # id, with its status visible -- hiding happens in the paged list desks.
  @moduledoc false

  alias QueryBookclub.BookclubQueryStore

  def find(member_id) when is_binary(member_id) do
    found(
      BookclubQueryStore.q(
        "SELECT member_id, club_id, name, status, registered_at FROM members WHERE member_id = ?",
        [member_id]
      )
    )
  end

  def find(_), do: {:error, :missing_member_id}

  defp found([[member_id, club_id, name, status, at] | _]) do
    {:ok,
     %{member_id: member_id, club_id: club_id, name: name, status: status, registered_at: at}}
  end

  defp found([]), do: {:error, :not_found}
  defp found({:error, reason}), do: {:error, {:store_error, reason}}
end

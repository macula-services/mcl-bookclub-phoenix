defmodule ProjectBookclub.MemberUnregistered.MemberUnregisteredV1ToSqliteMembers do
  # Projects member_unregistered_v1 into the members table.
  #
  # Self-contained like the club's archived projection: the event echoes
  # the member's club, name and registration time, so this write never
  # depends on the registered event having arrived first. The status
  # string comes from MemberStatus.to_string/1 -- never a literal of this
  # file's own (Demon 68).
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.MemberStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["member_unregistered_v1"]

  @impl true
  def replay_policy, do: :deliver

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)

    result =
      BookclubReadModelStore.exec(
        "INSERT OR REPLACE INTO members" <>
          " (member_id, club_id, name, status, registered_at, event_id, version)" <>
          " VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          data[:member_id],
          data[:club_id],
          data[:name],
          MemberStatus.to_string(MemberStatus.unregistered()),
          data[:registered_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:members, "member_unregistered_v1", data[:member_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

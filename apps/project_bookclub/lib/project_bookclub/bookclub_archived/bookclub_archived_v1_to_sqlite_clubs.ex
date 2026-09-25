defmodule ProjectBookclub.BookclubArchived.BookclubArchivedV1ToSqliteClubs do
  # Projects bookclub_archived_v1 into the clubs table.
  #
  # The same idempotent shape as the initiated projection: INSERT OR
  # REPLACE keyed on the stream id, the row carrying the applied position
  # (event_id, version), and the status string taken from
  # BookclubStatus.to_string/1 -- never a literal of this file's own
  # (Demon 68). Because the archived event is self-contained -- it echoes
  # name, initiated_by and initiated_at -- this write does not depend on
  # the initiated event having arrived first, in this process's history or
  # at all.
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.BookclubStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["bookclub_archived_v1"]

  @impl true
  def replay_policy, do: :deliver

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)

    result =
      BookclubReadModelStore.exec(
        "INSERT OR REPLACE INTO clubs" <>
          " (club_id, name, status, initiated_by, initiated_at, event_id, version)" <>
          " VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          data[:club_id],
          data[:name],
          BookclubStatus.to_string(BookclubStatus.archived()),
          data[:initiated_by],
          data[:initiated_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:clubs, "bookclub_archived_v1", data[:club_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

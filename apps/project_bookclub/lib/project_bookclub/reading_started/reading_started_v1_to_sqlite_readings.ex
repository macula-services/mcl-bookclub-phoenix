defmodule ProjectBookclub.ReadingStarted.ReadingStartedV1ToSqliteReadings do
  # Projects reading_started_v1 into the readings table.
  #
  # The same idempotent shape as every projection here: INSERT OR REPLACE
  # keyed on the stream id, the applied position in the row, and the
  # status string taken from ReadingStatus.to_string/1 -- never a literal
  # of this file's own (Demon 68). A reading born in progress has zero
  # pages read and no finish time -- the finished event fills both in.
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.ReadingStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["reading_started_v1"]

  @impl true
  def replay_policy, do: :deliver

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)

    result =
      BookclubReadModelStore.exec(
        "INSERT OR REPLACE INTO readings" <>
          " (reading_id, member_id, book_id, status, started_at, pages_read," <>
          "  finished_at, event_id, version)" <>
          " VALUES (?, ?, ?, ?, ?, 0, NULL, ?, ?)",
        [
          data[:reading_id],
          data[:member_id],
          data[:book_id],
          ReadingStatus.to_string(ReadingStatus.in_progress()),
          data[:started_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:readings, "reading_started_v1", data[:reading_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

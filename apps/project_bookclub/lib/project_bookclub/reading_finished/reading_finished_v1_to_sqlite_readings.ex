defmodule ProjectBookclub.ReadingFinished.ReadingFinishedV1ToSqliteReadings do
  # Projects reading_finished_v1 into the readings table.
  #
  # The fold, made safe: the finished event echoes the member, the book
  # and the start time, so this write rebuilds the whole row from its own
  # payload -- an absolute, idempotent write that never depends on the
  # started event having arrived first. The status string comes from
  # ReadingStatus.to_string/1 -- never a literal of this file's own
  # (Demon 68).
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.ReadingStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["reading_finished_v1"]

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
          " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          data[:reading_id],
          data[:member_id],
          data[:book_id],
          ReadingStatus.to_string(ReadingStatus.finished()),
          data[:started_at],
          data[:pages_read],
          data[:finished_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:readings, "reading_finished_v1", data[:reading_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

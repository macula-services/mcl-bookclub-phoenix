defmodule ProjectBookclub.BookclubInitiated.BookclubInitiatedV1ToSqliteClubs do
  # Projects bookclub_initiated_v1 into the clubs table.
  #
  # The same idempotent shape as the Erlang bookclub: INSERT OR REPLACE
  # keyed on the stream id, the readable status computed HERE, and the row
  # carrying the applied position (event_id, version). replay_policy/0 is
  # :deliver -- the write is idempotent, so a replay must re-apply, not
  # skip.
  @moduledoc false

  @behaviour :evoq_event_handler

  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["bookclub_initiated_v1"]

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
          " VALUES (?, ?, 'active', ?, ?, ?, ?)",
        [data[:club_id], data[:name], data[:initiated_by], data[:initiated_at],
         Map.get(event, :event_id), Map.get(event, :version, 0)]
      )

    case result do
      :ok -> {:ok, state}
      {:error, reason} -> {:error, {:store_error, reason}}
    end
  end
end

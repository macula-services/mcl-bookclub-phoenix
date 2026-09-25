defmodule ProjectBookclub.BookRetired.BookRetiredV1ToSqliteBooks do
  # Projects book_retired_v1 into the books table.
  #
  # Self-contained like the other soft-delete projections: the event
  # echoes the bibliographic facts, so this write never depends on the
  # procured event having arrived first. The status string comes from
  # BookStatus.to_string/1 -- never a literal of this file's own
  # (Demon 68).
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.BookStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["book_retired_v1"]

  @impl true
  def replay_policy, do: :deliver

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)

    result =
      BookclubReadModelStore.exec(
        "INSERT OR REPLACE INTO books" <>
          " (book_id, club_id, title, author, status, procured_at, event_id, version)" <>
          " VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
          data[:book_id],
          data[:club_id],
          data[:title],
          data[:author],
          BookStatus.to_string(BookStatus.retired()),
          data[:procured_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:books, "book_retired_v1", data[:book_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

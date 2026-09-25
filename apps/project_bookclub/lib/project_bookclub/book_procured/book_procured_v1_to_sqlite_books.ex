defmodule ProjectBookclub.BookProcured.BookProcuredV1ToSqliteBooks do
  # Projects book_procured_v1 into the books table.
  #
  # The same idempotent shape as the other projections: INSERT OR REPLACE
  # keyed on the stream id, the row carrying the applied position
  # (event_id, version), and the status string taken from
  # BookStatus.to_string/1 -- never a literal of this file's own
  # (Demon 68).
  @moduledoc false

  @behaviour :evoq_event_handler

  alias HostBookclub.BookStatus
  alias ProjectBookclub.BookclubChanged
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def interested_in, do: ["book_procured_v1"]

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
          BookStatus.to_string(BookStatus.on_shelf()),
          data[:procured_at],
          Map.get(event, :event_id),
          Map.get(event, :version, 0)
        ]
      )

    case result do
      :ok ->
        BookclubChanged.broadcast(:books, "book_procured_v1", data[:book_id])
        {:ok, state}

      {:error, reason} ->
        {:error, {:store_error, reason}}
    end
  end
end

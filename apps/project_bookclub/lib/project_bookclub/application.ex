defmodule ProjectBookclub.Application do
  # OTP application entry for the PRJ division: the sqlite read-model
  # store, then one evoq_event_handler child per projection desk.
  @moduledoc false
  use Application

  alias ProjectBookclub.BookclubInitiated.BookclubInitiatedV1ToSqliteClubs
  alias ProjectBookclub.BookclubReadModelStore

  @impl true
  def start(_type, _args) do
    children = [
      {BookclubReadModelStore, sqlite_path()},
      # evoq's handler supervisor wraps the projection module.
      %{
        id: BookclubInitiatedV1ToSqliteClubs,
        start:
          {:evoq_event_handler, :start_link, [BookclubInitiatedV1ToSqliteClubs, %{}]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ProjectBookclub.Supervisor)
  end

  defp sqlite_path do
    Path.join(data_dir(), "bookclub.sqlite3")
  end

  defp data_dir do
    case System.get_env("MCL_DATA_DIR") do
      nil -> "/tmp/mcl_bookclub"
      "" -> "/tmp/mcl_bookclub"
      path -> path
    end
  end
end

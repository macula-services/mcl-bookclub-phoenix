defmodule ProjectBookclub.Application do
  # OTP application entry for the PRJ division: the pubsub seam first (so
  # every projection can broadcast the moment it starts), then the sqlite
  # read-model store, then one evoq_event_handler child per projection
  # desk.
  #
  # Starting the shared PubSub registry here -- even though the name says
  # "web" -- is deliberate, the whiteboard's own arrangement: the umbrella's
  # boot order always starts project_bookclub before mcl_bookclub_phoenix_web
  # (the web app depends on this one), so a projection writing in the split
  # second before the web app exists can never hit an unknown registry. The
  # writer side owning the registry makes the race impossible by
  # construction rather than by hoping boot is fast.
  @moduledoc false

  use Application

  alias ProjectBookclub.BookclubArchived.BookclubArchivedV1ToSqliteClubs
  alias ProjectBookclub.BookclubInitiated.BookclubInitiatedV1ToSqliteClubs
  alias ProjectBookclub.BookclubReadModelStore
  alias ProjectBookclub.BookProcured.BookProcuredV1ToSqliteBooks
  alias ProjectBookclub.BookRetired.BookRetiredV1ToSqliteBooks
  alias ProjectBookclub.MemberRegistered.MemberRegisteredV1ToSqliteMembers
  alias ProjectBookclub.MemberUnregistered.MemberUnregisteredV1ToSqliteMembers
  alias ProjectBookclub.ReadingFinished.ReadingFinishedV1ToSqliteReadings
  alias ProjectBookclub.ReadingStarted.ReadingStartedV1ToSqliteReadings

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: MclBookclubPhoenixWeb.PubSub},
      {BookclubReadModelStore, sqlite_path()},
      handler(BookclubInitiatedV1ToSqliteClubs),
      handler(BookclubArchivedV1ToSqliteClubs),
      handler(MemberRegisteredV1ToSqliteMembers),
      handler(MemberUnregisteredV1ToSqliteMembers),
      handler(BookProcuredV1ToSqliteBooks),
      handler(BookRetiredV1ToSqliteBooks),
      handler(ReadingStartedV1ToSqliteReadings),
      handler(ReadingFinishedV1ToSqliteReadings)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ProjectBookclub.Supervisor)
  end

  # evoq's handler supervisor wraps the projection module.
  defp handler(module) do
    %{
      id: module,
      start: {:evoq_event_handler, :start_link, [module, %{}]},
      restart: :permanent,
      shutdown: 5_000,
      type: :worker,
      modules: [module]
    }
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

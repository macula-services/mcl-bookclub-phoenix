defmodule QueryBookclub.BookclubQueryStore do
  # The QRY division's sqlite store: one GenServer owning one esqlite
  # connection. READ-ONLY BY API: only q/2 is exposed, so a query module
  # cannot write. The schema is owned by the PRJ division; this process
  # opens the same file and assumes it exists.
  @moduledoc false

  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def q(sql, args), do: GenServer.call(__MODULE__, {:q, sql, args}, 5000)

  @impl true
  def init(_) do
    path = String.to_charlist(sqlite_path())
    :ok = File.mkdir_p(Path.dirname(sqlite_path()))

    case :esqlite3.open(path) do
      {:ok, conn} -> {:ok, %{conn: conn}}
      {:error, reason} -> {:stop, {:open_failed, reason}}
    end
  end

  @impl true
  def handle_call({:q, sql, args}, _from, %{conn: conn} = state) do
    {:reply, :esqlite3.q(conn, sql, args), state}
  end

  def handle_call(:ping, _from, state), do: {:reply, :ok, state}

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

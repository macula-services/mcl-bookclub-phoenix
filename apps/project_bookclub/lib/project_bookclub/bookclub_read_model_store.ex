defmodule ProjectBookclub.BookclubReadModelStore do
  # The PRJ division's sqlite store: one GenServer owning one esqlite
  # connection (a NIF connection belongs to the process that opened it).
  # The DDL lives here and ONLY here; writes are single idempotent
  # statements.
  @moduledoc false

  use GenServer

  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: __MODULE__)
  end

  def exec(sql, args), do: GenServer.call(__MODULE__, {:exec, sql, args}, 5000)
  def q(sql, args), do: GenServer.call(__MODULE__, {:q, sql, args}, 5000)

  def schema do
    [
      "CREATE TABLE IF NOT EXISTS clubs (" <>
        " club_id      TEXT PRIMARY KEY," <>
        " name         TEXT NOT NULL," <>
        " status       TEXT NOT NULL," <>
        " initiated_by TEXT NOT NULL," <>
        " initiated_at INTEGER NOT NULL," <>
        " event_id     TEXT NOT NULL," <>
        " version      INTEGER NOT NULL)"
    ]
  end

  @impl true
  def init(path) do
    :ok = File.mkdir_p(Path.dirname(path))

    case :esqlite3.open(String.to_charlist(path)) do
      {:ok, conn} ->
        case create_schema(conn, schema()) do
          :ok -> {:ok, %{conn: conn}}
          {:error, reason} -> {:stop, {:schema_failed, reason}}
        end

      {:error, reason} ->
        {:stop, {:open_failed, reason}}
    end
  end

  @impl true
  def handle_call({:exec, sql, args}, _from, %{conn: conn} = state) do
    {:reply, do_exec(conn, sql, args), state}
  end

  def handle_call({:q, sql, args}, _from, %{conn: conn} = state) do
    {:reply, :esqlite3.q(conn, sql, args), state}
  end

  def handle_call(:ping, _from, state), do: {:reply, :ok, state}

  defp create_schema(_conn, []), do: :ok

  defp create_schema(conn, [sql | rest]) do
    case :esqlite3.exec(conn, sql) do
      :ok -> create_schema(conn, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_exec(conn, sql, args) do
    case :esqlite3.q(conn, sql, args) do
      [] -> :ok
      {:error, reason} -> {:error, reason}
      rows -> {:error, {:unexpected_rows, rows}}
    end
  end
end

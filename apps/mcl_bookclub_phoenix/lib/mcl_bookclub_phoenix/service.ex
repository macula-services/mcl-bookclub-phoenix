defmodule MclBookclubPhoenix.Service do
  # The mcl_om service contract, in Elixir: the SAME org, topics and
  # procedure names as the Erlang bookclub -- a drop-in second club on the
  # mesh, distinguishable only by node identity. The contract is shared;
  # the club is a payload parameter (club_id and club_name in every fact).
  @moduledoc false

  @behaviour :mcl_om_service

  alias ProjectBookclub.BookclubReadModelStore
  alias QueryBookclub.BookclubQueryStore

  @impl true
  def info do
    %{
      name: "mcl-bookclub",
      version: "0.1.0",
      description: "A book club kept as a reckon-db event store, in Elixir."
    }
  end

  @impl true
  def start(_opts), do: MclBookclubPhoenix.Supervisor.start_link()

  @impl true
  def stop(_state), do: :ok

  # The service's health IS the health of its read path: the two sqlite
  # store processes the divisions run. Their absence or silence means the
  # club's record is unreachable, however healthy the rest of the node
  # looks.
  @impl true
  def health do
    case {ping(BookclubReadModelStore), ping(BookclubQueryStore)} do
      {:ok, :ok} ->
        :ok

      {read_model, query} ->
        {:degraded, %{read_model_store: read_model, query_store: query}}
    end
  end

  # The stores are gen_servers; a missing or dead one exits on call. The
  # catch below turns that into the honest `:missing' signal instead of
  # taking the whole health request down with it -- the same try/catch the
  # Erlang twin uses, for the same reason.
  defp ping(name) do
    GenServer.call(name, :ping, 1000)
  catch
    :exit, _ -> :missing
  end

  # WHAT THIS SERVICE ANNOUNCES IT CAN DO. Each entry is a promise that
  # something answers: get_bookclub_by_id is the mesh procedure, wired to
  # the QRY desk through MclBookclubPhoenix.GetBookclubByIdHandler -- the
  # SAME procedure name the Erlang twin advertises, so a peer cannot tell
  # the two apart.
  @impl true
  def capabilities do
    [
      %{
        name: "get_bookclub_by_id",
        version: 1,
        handler: {MclBookclubPhoenix.GetBookclubByIdHandler, []},
        auth: :open
      }
    ]
  end

  # THE AUTHORITY THIS SERVICE ASKS THE REALM FOR, and deliberately
  # nothing more: the one procedure it serves and the three fact topics
  # its emitters publish. Popped, an attacker gains precisely this and no
  # more, which is the whole point of listing it.
  @impl true
  def identity_spec do
    %{
      scope: "mcl-bookclub",
      actions: ["get_bookclub_by_id"],
      resources: [
        "bookclub/member/member_registered_v1",
        "bookclub/book/book_procured_v1",
        "bookclub/book/book_retired_v1"
      ],
      ttl_days: 30
    }
  end

  # THE STORE THIS SERVICE OWNS, described here and opened by
  # MclBookclubPhoenix.Application in start/2 before mcl_om:boot/1.
  #
  # ⚠ NOT store_id/0 AND data_dir/0. That pair was the pre-0.35 contract, when
  # mcl_om:boot/1 opened a store a service exported the two for. It opens none
  # since 0.35.0 (mcl-om#10) and only logs a warning naming them, so a service
  # that still carries the pair compiles clean, boots green and has NO store:
  # every command and projection is lost at its first touch.
  #
  # The directory is a CHARLIST, not a binary: the dets/ra layer under
  # reckon-db rejects a binary file option with {badarg, ...} (the whiteboard's
  # runtime.exs documents the same trap).
  @doc """
  The reckon-db store this service owns.

  The id is named twice, here and as `store_id` in the evoq block of
  `config/runtime.exs`; a test compares them. The directory is `MCL_DATA_DIR`,
  a mounted volume on a box.
  """
  @spec event_store() :: map()
  def event_store do
    %{
      id: :mcl_bookclub_store,
      dir: data_dir(),
      indexes: [],
      mode: :single,
      integrity: :disabled
    }
  end

  defp data_dir do
    dir =
      case System.get_env("MCL_DATA_DIR") do
        nil -> "/tmp/mcl_bookclub"
        "" -> "/tmp/mcl_bookclub"
        path -> path
      end

    String.to_charlist(dir)
  end
end

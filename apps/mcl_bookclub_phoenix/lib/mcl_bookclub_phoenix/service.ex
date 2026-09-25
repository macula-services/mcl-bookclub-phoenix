defmodule MclBookclubPhoenix.Service do
  # The mcl_om service contract, in Elixir: the SAME org, topics and
  # procedure names as the Erlang bookclub -- a drop-in second club on the
  # mesh, distinguishable only by node identity. The contract is shared;
  # the club is a payload parameter (club_id and club_name in every fact).
  @moduledoc false

  @behaviour :mcl_om_service

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

  @impl true
  def health, do: :ok

  # Nothing advertised yet: the walking skeleton's query is answered
  # locally until the capability slice.
  @impl true
  def capabilities, do: []

  @impl true
  def identity_spec do
    %{scope: "mcl-bookclub", actions: [], resources: [], ttl_days: 30}
  end

  # The store the service owns -- the same two callbacks, in Elixir, that
  # make mcl_om:boot/1 open the store and its subscription. The path is a
  # CHARLIST, not a binary: the dets/ra layer under reckon-db rejects a
  # binary file option with {badarg, ...} (the whiteboard's runtime.exs
  # documents the same trap).
  @impl true
  def store_id, do: :mcl_bookclub_store

  @impl true
  def data_dir do
    dir =
      case System.get_env("MCL_DATA_DIR") do
        nil -> "/tmp/mcl_bookclub"
        "" -> "/tmp/mcl_bookclub"
        path -> path
      end

    String.to_charlist(dir)
  end
end

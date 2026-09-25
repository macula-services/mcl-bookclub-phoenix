defmodule MclBookclubPhoenix.Application do
  # OTP application entry: mcl_om:boot/1 wires the mesh, the realm
  # identity, capabilities, health and -- because the service exports
  # store_id/0 + data_dir/0 -- the reckon-db store and its subscription
  # BEFORE start/1 fires.
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    :mcl_om.boot(MclBookclubPhoenix.Service)
  end
end

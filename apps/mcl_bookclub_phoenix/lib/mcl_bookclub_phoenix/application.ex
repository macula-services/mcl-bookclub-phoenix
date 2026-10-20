defmodule MclBookclubPhoenix.Application do
  # OTP application entry. THIS SERVICE OPENS ITS OWN STORE FIRST
  # (MclBookclubPhoenix.EventStore, from MclBookclubPhoenix.Service.event_store/0),
  # then lets mcl_om:boot/1 wire the mesh, the realm identity, capabilities and
  # health and start the service. mcl_om opens no store since 0.35.0 (mcl-om#10):
  # the old store_id/0 + data_dir/0 contract silently boots with no store at
  # all, so this ordering is the whole of persistence for this service.
  #
  # The divisions are runtime deps of this app, so their projections and
  # process managers are registered before the store subscription delivers.
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    :ok = MclBookclubPhoenix.EventStore.open(MclBookclubPhoenix.Service.event_store())
    :mcl_om.boot(MclBookclubPhoenix.Service)
  end
end

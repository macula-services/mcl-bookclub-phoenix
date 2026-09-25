defmodule MclBookclubPhoenix.GetBookclubByIdHandler do
  # The mesh face of get_bookclub_by_id, advertised as
  # `mcl-bookclub/get_bookclub_by_id'.
  #
  # The capability handler -- the one place the QRY desk's answer crosses
  # onto the mesh. The desk stays pure (no mesh, no wire); this module
  # adapts between the wire and it. Parameters arrive atom-keyed or
  # binary-keyed or CBOR-text-wrapped (all three exist in the wild), so
  # they are read with mcl_om_wire:field/2 -- the tolerant reader the
  # corpus's Demon 65 prescribes -- and the reply's text goes back out as
  # CBOR text.
  @moduledoc false

  @behaviour :macula_response

  alias QueryBookclub.GetBookclubById.GetBookclubById

  @impl true
  def init(_args), do: {:ok, nil}

  @impl true
  def handle_request(payload, state) do
    club_id = :mcl_om_wire.field(:club_id, payload) |> :mcl_om_wire.unwrap()
    replied(GetBookclubById.find(club_id), state)
  end

  defp replied({:ok, club}, state), do: {:reply, to_wire(club), state}
  defp replied({:error, reason}, state), do: {:error, reason, state}

  defp to_wire(b) when is_binary(b), do: {:text, b}
  defp to_wire(true), do: 1
  defp to_wire(false), do: 0
  defp to_wire(m) when is_map(m), do: Map.new(m, fn {k, v} -> {k, to_wire(v)} end)
  defp to_wire(other), do: other
end

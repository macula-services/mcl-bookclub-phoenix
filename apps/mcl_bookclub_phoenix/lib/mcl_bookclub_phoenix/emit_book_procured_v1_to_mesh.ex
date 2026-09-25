defmodule MclBookclubPhoenix.EmitBookProcuredV1ToMesh do
  # Emitter: each `book_procured_v1' becomes one `book_procured_v1' fact
  # on the mesh.
  #
  # Same choices as EmitMemberRegisteredV1ToMesh: replay_policy :skip (a
  # replay must not re-publish), and a failed publish is an error return
  # so evoq's retry machinery owns redelivery of this lifecycle fact.
  @moduledoc false

  @behaviour :evoq_event_handler

  alias MclBookclubPhoenix.Facts

  @impl true
  def interested_in, do: ["book_procured_v1"]

  @impl true
  def replay_policy, do: :skip

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)
    publish(Facts.to_wire(Facts.book_procured(data)), state)
  end

  defp publish(fact, state) do
    case :mcl_om.mesh_handles() do
      {:ok, pool, realm} -> publish_on(pool, realm, fact, state)
      {:error, _} = error -> error
    end
  end

  defp publish_on(pool, realm, fact, state) do
    case :macula.publish(
           pool,
           realm,
           Facts.topic(Facts.realm_name(), :book_procured),
           fact
         ) do
      :ok -> {:ok, state}
      {:error, _} = error -> error
    end
  end
end

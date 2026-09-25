defmodule MclBookclubPhoenix.EmitMemberRegisteredV1ToMesh do
  # Emitter: each `member_registered_v1' becomes one
  # `member_registered_v1' fact on the mesh.
  #
  # The only place this desk's event touches the mesh. The dispatch path
  # never waits for it: the fact goes out on the router's delivery, not
  # the caller's.
  #
  # TWO DELIBERATE CHOICES, each worth understanding before copying:
  #
  # - replay_policy/0 is :skip: a restart's replay of the store's history
  #   must not re-publish facts that already went out.
  #
  # - A failed publish is an ERROR RETURN, so evoq's retry machinery owns
  #   redelivery: lifecycle facts (unlike telemetry) are worth retrying --
  #   a consumer that missed "member registered" is missing state, not a
  #   sample.
  @moduledoc false

  @behaviour :evoq_event_handler

  alias MclBookclubPhoenix.Facts

  @impl true
  def interested_in, do: ["member_registered_v1"]

  @impl true
  def replay_policy, do: :skip

  @impl true
  def init(_config), do: {:ok, %{}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)
    publish(Facts.to_wire(Facts.member_registered(data)), state)
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
           Facts.topic(Facts.realm_name(), :member_registered),
           fact
         ) do
      :ok -> {:ok, state}
      {:error, _} = error -> error
    end
  end
end

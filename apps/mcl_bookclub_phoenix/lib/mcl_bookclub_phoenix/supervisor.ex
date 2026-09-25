defmodule MclBookclubPhoenix.Supervisor do
  # The facade's own supervisor: the three mesh emitters. Every other
  # process lives in a division's tree, and mcl_om owns the mesh-side
  # processes.
  #
  # The emitters are children HERE, not in host_bookclub, because the
  # Phoenix repo's division boundary is stricter than the Erlang twin's:
  # host_bookclub has no mesh SDK in its deps, so anything that touches
  # the mesh lives in the facade. They start after mcl_om:boot/1's
  # catch-up replay has run, which is harmless for :skip handlers --
  # replayed history is skipped anyway, and live events only ever reach
  # a registered handler.
  @moduledoc false

  use Supervisor

  alias MclBookclubPhoenix.{
    EmitBookProcuredV1ToMesh,
    EmitBookRetiredV1ToMesh,
    EmitMemberRegisteredV1ToMesh
  }

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      handler(EmitMemberRegisteredV1ToMesh),
      handler(EmitBookProcuredV1ToMesh),
      handler(EmitBookRetiredV1ToMesh)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

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
end

defmodule MclBookclubPhoenix.Supervisor do
  # The facade's own supervisor: empty by design -- every process lives in
  # a division's tree, and mcl_om owns the mesh-side processes.
  @moduledoc false
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end
end

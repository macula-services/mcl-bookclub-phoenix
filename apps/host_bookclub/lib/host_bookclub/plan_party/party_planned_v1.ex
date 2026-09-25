defmodule HostBookclub.PlanParty.PartyPlannedV1 do
  # The party_planned_v1 event: a fact about the past.
  #
  # It carries the club's NEW party count, echoed from the aggregate
  # state: a downstream consumer can rebuild the club's party tally from
  # this event alone, and the fold is an absolute assignment (applying the
  # same event twice sets the same count), never a relative increment.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:club_id, :parties_planned, :planned_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "party_planned_v1"

  @impl true
  def new(%{club_id: club_id, parties_planned: parties})
      when is_binary(club_id) and is_integer(parties) and parties >= 0 do
    {:ok,
     %__MODULE__{
       club_id: club_id,
       parties_planned: parties,
       planned_at: System.system_time(:millisecond)
     }}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{
      event_type: event_type(),
      club_id: event.club_id,
      parties_planned: event.parties_planned,
      planned_at: event.planned_at
    }
  end
end

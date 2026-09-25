defmodule HostBookclub.RegisterMember.MemberRegisteredV1 do
  # The member_registered_v1 event: a fact about the past.
  #
  # Self-contained: it carries the club the member joined, so any
  # downstream consumer (the plan_party policy, the mesh emitter, the
  # projection) reads one event and knows everything it needs.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:member_id, :club_id, :name, :club_name, :registered_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "member_registered_v1"

  @impl true
  def new(%{member_id: member_id, club_id: club_id, name: name} = params)
      when is_binary(member_id) and is_binary(club_id) and is_binary(name) do
    {:ok,
     %__MODULE__{
       member_id: member_id,
       club_id: club_id,
       name: name,
       club_name: Map.get(params, :club_name, ""),
       registered_at: System.system_time(:millisecond)
     }}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{
      event_type: event_type(),
      member_id: event.member_id,
      club_id: event.club_id,
      name: event.name,
      club_name: event.club_name,
      registered_at: event.registered_at
    }
  end
end

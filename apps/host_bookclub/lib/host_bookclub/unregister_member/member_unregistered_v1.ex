defmodule HostBookclub.UnregisterMember.MemberUnregisteredV1 do
  # The member_unregistered_v1 event: a fact about the past.
  #
  # SELF-CONTAINED, like the club's archived event: it echoes the member's
  # club, name and registration time from the aggregate state, so its
  # projection stays an absolute, idempotent write that never depends on
  # the registered event having arrived first.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:member_id, :club_id, :name, :registered_at, :unregistered_by, :unregistered_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "member_unregistered_v1"

  @impl true
  def new(%{
        member_id: member_id,
        club_id: club_id,
        name: name,
        registered_at: at,
        unregistered_by: by
      })
      when is_binary(member_id) and is_binary(club_id) and is_binary(name) and
             is_integer(at) and is_binary(by) do
    {:ok,
     %__MODULE__{
       member_id: member_id,
       club_id: club_id,
       name: name,
       registered_at: at,
       unregistered_by: by,
       unregistered_at: System.system_time(:millisecond)
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
      registered_at: event.registered_at,
      unregistered_by: event.unregistered_by,
      unregistered_at: event.unregistered_at
    }
  end
end

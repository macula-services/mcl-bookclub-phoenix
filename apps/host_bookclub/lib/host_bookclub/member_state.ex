defmodule HostBookclub.MemberState do
  # The member aggregate's state: the struct, its fold, its shape.
  #
  # The state module is the only module that sees the struct. Like the
  # club's state, it remembers the birth details (club_id, name,
  # registered_at), so the unregistered event can echo them and stay
  # self-contained for its projection.
  @moduledoc false

  defstruct [:member_id, :club_id, :name, :registered_at, status: 0]

  alias HostBookclub.MemberStatus

  def new(member_id), do: %__MODULE__{member_id: member_id}

  # evoq hands apply/2 TWO SHAPES for the same event: the raw event right
  # after execute/2 (business fields inline) and the stored envelope on
  # reload (business fields under "data"). Read tolerantly.
  def apply_event(state, %{event_type: "member_registered_v1"} = event) do
    data = event_data(event)

    %{
      state
      | club_id: data["club_id"] || data[:club_id],
        name: data["name"] || data[:name],
        registered_at: data["registered_at"] || data[:registered_at] || 0,
        status: :evoq_bit_flags.set(state.status, MemberStatus.registered())
    }
  end

  def apply_event(state, %{event_type: "member_unregistered_v1"}) do
    %{state | status: :evoq_bit_flags.set(state.status, MemberStatus.unregistered())}
  end

  def apply_event(state, _event), do: state

  def registered?(state), do: :evoq_bit_flags.has(state.status, MemberStatus.registered())
  def unregistered?(state), do: :evoq_bit_flags.has(state.status, MemberStatus.unregistered())
  def status(state), do: state.status

  defp event_data(%{data: data}), do: data
  defp event_data(event), do: event
end

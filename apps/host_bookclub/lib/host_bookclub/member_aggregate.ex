defmodule HostBookclub.MemberAggregate do
  # Aggregate root for a book-club member.
  #
  # One stream per member, born by register_member_v1 and soft-deleted by
  # unregister_member_v1. Like the club, the aggregate owns a blanket
  # lifecycle guard: every command on an unregistered stream is refused
  # before any desk sees it. The member's stream id IS its identity,
  # minted by the caller, never derived from the human name.
  @moduledoc false

  @behaviour :evoq_aggregate

  alias HostBookclub.MemberState
  alias HostBookclub.RegisterMember.MaybeRegisterMember
  alias HostBookclub.UnregisterMember.MaybeUnregisterMember

  @impl true
  def state_module, do: MemberState

  @impl true
  def init(member_id), do: {:ok, MemberState.new(member_id)}

  @impl true
  def apply(state, event), do: MemberState.apply_event(state, event)

  @impl true
  def execute(state, %{command_type: :register_member_v1} = payload) do
    guarded(state, payload, &MaybeRegisterMember.handle_from_map/2)
  end

  def execute(state, %{command_type: :unregister_member_v1} = payload) do
    guarded(state, payload, &MaybeUnregisterMember.handle_from_map/2)
  end

  def execute(_state, _payload), do: {:error, :unknown_command}

  defp guarded(state, payload, desk) do
    if MemberState.unregistered?(state) do
      {:error, :unregistered}
    else
      desk.(state, payload)
    end
  end

  def stream_id(member_id), do: member_id
end

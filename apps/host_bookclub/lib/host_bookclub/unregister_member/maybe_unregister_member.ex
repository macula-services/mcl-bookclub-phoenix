defmodule HostBookclub.UnregisterMember.MaybeUnregisterMember do
  # Handler for unregister_member_v1: the desk owns the business rule (a
  # member unregisters only once it exists), produces the matching
  # member_unregistered_v1 event, and dispatches. The aggregate calls
  # handle_from_map/2; callers dispatch/1. The already-unregistered
  # refusal is the aggregate's blanket guard, not this desk's.
  @moduledoc false

  alias HostBookclub.MemberAggregate
  alias HostBookclub.MemberState
  alias HostBookclub.UnregisterMember.{MemberUnregisteredV1, UnregisterMemberV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :unregister_member_v1} = payload) do
    case UnregisterMemberV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %UnregisterMemberV1{} = cmd) do
    case {MemberState.registered?(state), UnregisterMemberV1.validate(cmd)} do
      {false, _} ->
        {:error, :not_registered}

      {true, :ok} ->
        events(state, cmd)

      {true, {:error, _} = error} ->
        error
    end
  end

  defp events(state, cmd) do
    event =
      MemberUnregisteredV1.new(%{
        member_id: state.member_id,
        club_id: state.club_id,
        name: state.name,
        registered_at: state.registered_at,
        unregistered_by: cmd.unregistered_by
      })

    case event do
      {:ok, e} -> {:ok, [MemberUnregisteredV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{member_id: _member_id} = params) do
    with {:ok, cmd} <- UnregisterMemberV1.new(params),
         :ok <- UnregisterMemberV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :unregister_member_v1,
          MemberAggregate,
          UnregisterMemberV1.stream_id(cmd),
          UnregisterMemberV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

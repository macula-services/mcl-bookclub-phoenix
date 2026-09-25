defmodule HostBookclub.RegisterMember.MaybeRegisterMember do
  # Handler for register_member_v1: the desk owns the business rule (a
  # member registers once), produces the matching member_registered_v1
  # event, and dispatches. The aggregate calls handle_from_map/2; callers
  # dispatch/1. The already-unregistered refusal is the aggregate's
  # blanket guard, not this desk's.
  @moduledoc false

  alias HostBookclub.MemberAggregate
  alias HostBookclub.MemberState
  alias HostBookclub.RegisterMember.{MemberRegisteredV1, RegisterMemberV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :register_member_v1} = payload) do
    case RegisterMemberV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %RegisterMemberV1{} = cmd) do
    case {MemberState.registered?(state), RegisterMemberV1.validate(cmd)} do
      {true, _} ->
        {:error, :already_registered}

      {false, :ok} ->
        events(cmd)

      {false, {:error, _} = error} ->
        error
    end
  end

  defp events(cmd) do
    event =
      MemberRegisteredV1.new(%{
        member_id: cmd.member_id,
        club_id: cmd.club_id,
        name: cmd.name,
        club_name: cmd.club_name
      })

    case event do
      {:ok, e} -> {:ok, [MemberRegisteredV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{member_id: _member_id} = params) do
    with {:ok, cmd} <- RegisterMemberV1.new(params),
         :ok <- RegisterMemberV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :register_member_v1,
          MemberAggregate,
          RegisterMemberV1.stream_id(cmd),
          RegisterMemberV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

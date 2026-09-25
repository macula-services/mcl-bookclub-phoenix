defmodule HostBookclub.PlanParty.MaybePlanParty do
  # Handler for plan_party_v1: the desk owns the business rule (a party is
  # planned for an initiated club), produces the matching party_planned_v1
  # event with the incremented count echoed from state, and dispatches.
  # The archived refusal is the aggregate's blanket guard.
  @moduledoc false

  alias HostBookclub.BookclubAggregate
  alias HostBookclub.BookclubState
  alias HostBookclub.PlanParty.{PartyPlannedV1, PlanPartyV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :plan_party_v1} = payload) do
    case PlanPartyV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %PlanPartyV1{} = cmd) do
    case {BookclubState.initiated?(state), PlanPartyV1.validate(cmd)} do
      {false, _} ->
        {:error, :not_initiated}

      {true, :ok} ->
        events(state)

      {true, {:error, _} = error} ->
        error
    end
  end

  # The count increments HERE, in the state the command runs against, and
  # the event carries the new count -- never a relative "+1" a consumer
  # would have to apply.
  defp events(state) do
    event =
      PartyPlannedV1.new(%{
        club_id: state.club_id,
        parties_planned: state.parties_planned + 1
      })

    case event do
      {:ok, e} -> {:ok, [PartyPlannedV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{club_id: _club_id} = params) do
    with {:ok, cmd} <- PlanPartyV1.new(params),
         :ok <- PlanPartyV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :plan_party_v1,
          BookclubAggregate,
          PlanPartyV1.stream_id(cmd),
          PlanPartyV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

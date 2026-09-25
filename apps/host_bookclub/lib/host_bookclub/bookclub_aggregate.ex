defmodule HostBookclub.BookclubAggregate do
  # Aggregate root for a book club.
  #
  # One stream per club, born by initiate_bookclub_v1 and soft-deleted by
  # archive_bookclub_v1. The aggregate is the consistency boundary: it
  # refuses a second initiation, every command once archived, and the
  # club's stream id IS its identity -- minted by the caller, never
  # derived from a human-readable name.
  #
  # The ARCHIVED guard lives HERE, in the aggregate, because it is a
  # blanket lifecycle rule over every command the stream will ever
  # accept. Desk rules (a club initiates once, archives once, a party
  # needs an initiated club) live in the desks. That is the split: the
  # aggregate owns the stream's lifecycle, the desk owns the business
  # rule.
  @moduledoc false

  @behaviour :evoq_aggregate

  alias HostBookclub.ArchiveBookclub.MaybeArchiveBookclub
  alias HostBookclub.BookclubState
  alias HostBookclub.InitiateBookclub.MaybeInitiateBookclub
  alias HostBookclub.PlanParty.MaybePlanParty

  @impl true
  def state_module, do: BookclubState

  @impl true
  def init(club_id), do: {:ok, BookclubState.new(club_id)}

  @impl true
  def apply(state, event), do: BookclubState.apply_event(state, event)

  @impl true
  def execute(state, %{command_type: :initiate_bookclub_v1} = payload) do
    guarded(state, payload, &MaybeInitiateBookclub.handle_from_map/2)
  end

  def execute(state, %{command_type: :archive_bookclub_v1} = payload) do
    guarded(state, payload, &MaybeArchiveBookclub.handle_from_map/2)
  end

  def execute(state, %{command_type: :plan_party_v1} = payload) do
    guarded(state, payload, &MaybePlanParty.handle_from_map/2)
  end

  def execute(_state, _payload), do: {:error, :unknown_command}

  # evoq calls execute(State, Payload) -- State FIRST. The guard rules live
  # in the desk's maybe_ module; the aggregate only dispatches on the
  # command type, which is the house split: the desk owns the business
  # rule, the aggregate owns the stream boundary.
  defp guarded(state, payload, desk) do
    if BookclubState.archived?(state) do
      {:error, :archived}
    else
      desk.(state, payload)
    end
  end

  def stream_id(club_id), do: club_id
end

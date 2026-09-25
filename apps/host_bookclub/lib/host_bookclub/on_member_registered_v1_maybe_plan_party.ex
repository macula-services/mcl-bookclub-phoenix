defmodule HostBookclub.OnMemberRegisteredV1MaybePlanParty do
  # Policy: every fifth member registration plans a club party.
  #
  # A policy is a sibling slice of the target CMD app, reacting to a domain
  # event and dispatching a command to another aggregate -- here, from a
  # member's stream to the club's. It is an evoq_event_handler with its own
  # small state, NOT an evoq_process_manager: the rule has no per-process
  # instance to correlate (see the corpus's behaviour decision guide).
  #
  # TWO DELIBERATE CHOICES, each worth understanding before copying:
  #
  # - replay_policy/0 is :skip: this handler's effect is a command
  #   dispatch, and repeating it on replay would plan duplicate parties. A
  #   handler with side effects must declare skip; a projection whose write
  #   is idempotent declares deliver.
  #
  # - The counter lives in the handler's in-memory state. A restart resets
  #   it, so the party cadence is best-effort entertainment, not a business
  #   invariant. The honest home for a durable counter is the club's own
  #   stream (a tally event) -- the shape the corpus prefers for anything
  #   that must survive a restart.
  @moduledoc false

  @behaviour :evoq_event_handler

  require Logger

  alias HostBookclub.PlanParty.MaybePlanParty

  @party_every 5

  @impl true
  def interested_in, do: ["member_registered_v1"]

  @impl true
  def replay_policy, do: :skip

  @impl true
  def init(_config), do: {:ok, %{registrations: 0}}

  @impl true
  def handle_event(_event_type, event, _metadata, state) do
    data = Map.get(event, :data, event)
    count = state.registrations + 1

    if rem(count, @party_every) == 0 do
      plan_party(field(:club_id, data))
    end

    {:ok, %{state | registrations: count}}
  end

  # The dispatch result is the only error channel. A party that cannot be
  # planned (an archived club, a race with archive) is logged, not thrown:
  # the policy must never take the delivery of every later event down with
  # it, and the club's own stream is the authority on whether a party
  # exists, not this handler.
  defp plan_party(club_id) do
    case MaybePlanParty.dispatch(%{club_id: club_id}) do
      {:ok, _version, _events} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "[plan_party] party_not_planned club_id=#{club_id} reason=#{inspect(reason)}"
        )
    end
  end

  defp field(key, map) when is_atom(key) do
    Map.get(map, key, Map.get(map, Atom.to_string(key)))
  end
end

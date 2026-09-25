defmodule HostBookclub.BookclubAggregate do
  # Aggregate root for a book club.
  #
  # One stream per club, born by initiate_bookclub_v1. The aggregate is
  # the consistency boundary: the desk owns the business rule, the
  # aggregate owns the stream's lifecycle (the blanket archived guard
  # arrives with the archive slice).
  @moduledoc false

  @behaviour :evoq_aggregate

  alias HostBookclub.BookclubState
  alias HostBookclub.InitiateBookclub.MaybeInitiateBookclub

  @impl true
  def state_module, do: BookclubState

  @impl true
  def init(club_id), do: {:ok, BookclubState.new(club_id)}

  @impl true
  def apply(state, event), do: BookclubState.apply_event(state, event)

  @impl true
  def execute(state, %{command_type: :initiate_bookclub_v1} = payload) do
    MaybeInitiateBookclub.handle_from_map(state, payload)
  end

  def execute(_state, _payload), do: {:error, :unknown_command}

  def stream_id(club_id), do: club_id
end

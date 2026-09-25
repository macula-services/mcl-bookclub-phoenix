defmodule HostBookclub.InitiateBookclub.MaybeInitiateBookclub do
  # Handler for initiate_bookclub_v1: the desk owns the business rule (a
  # club is initiated exactly once), produces the matching event, and
  # dispatches. The aggregate calls handle_from_map/2; callers dispatch/1.
  @moduledoc false

  alias HostBookclub.BookclubAggregate
  alias HostBookclub.BookclubState
  alias HostBookclub.InitiateBookclub.{BookclubInitiatedV1, InitiateBookclubV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :initiate_bookclub_v1} = payload) do
    case InitiateBookclubV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %InitiateBookclubV1{} = cmd) do
    case {BookclubState.initiated?(state), InitiateBookclubV1.validate(cmd)} do
      {true, _} ->
        {:error, :already_initiated}

      {false, :ok} ->
        event =
          BookclubInitiatedV1.new(%{
            club_id: cmd.club_id,
            name: cmd.name,
            initiated_by: cmd.initiated_by
          })

        case event do
          {:ok, e} -> {:ok, [BookclubInitiatedV1.to_map(e)]}
          {:error, _} = error -> error
        end

      {false, {:error, _} = error} ->
        error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{club_id: _club_id} = params) do
    with {:ok, cmd} <- InitiateBookclubV1.new(params),
         :ok <- InitiateBookclubV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :initiate_bookclub_v1,
          BookclubAggregate,
          InitiateBookclubV1.stream_id(cmd),
          InitiateBookclubV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

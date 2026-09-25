defmodule HostBookclub.FinishReading.MaybeFinishReading do
  # Handler for finish_reading_v1: the desk owns the business rule (a
  # reading finishes only once it is in progress), produces the matching
  # reading_finished_v1 event, and dispatches. The aggregate calls
  # handle_from_map/2; callers dispatch/1. The already-finished refusal is
  # the aggregate's blanket guard, not this desk's.
  @moduledoc false

  alias HostBookclub.FinishReading.{FinishReadingV1, ReadingFinishedV1}
  alias HostBookclub.ReadingAggregate
  alias HostBookclub.ReadingState

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :finish_reading_v1} = payload) do
    case FinishReadingV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %FinishReadingV1{} = cmd) do
    case {ReadingState.in_progress?(state), FinishReadingV1.validate(cmd)} do
      {false, _} ->
        {:error, :not_started}

      {true, :ok} ->
        events(state, cmd)

      {true, {:error, _} = error} ->
        error
    end
  end

  defp events(state, cmd) do
    event =
      ReadingFinishedV1.new(%{
        reading_id: state.reading_id,
        member_id: state.member_id,
        book_id: state.book_id,
        started_at: state.started_at,
        pages_read: cmd.pages_read
      })

    case event do
      {:ok, e} -> {:ok, [ReadingFinishedV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{reading_id: _reading_id} = params) do
    with {:ok, cmd} <- FinishReadingV1.new(params),
         :ok <- FinishReadingV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :finish_reading_v1,
          ReadingAggregate,
          FinishReadingV1.stream_id(cmd),
          FinishReadingV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

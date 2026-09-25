defmodule HostBookclub.StartReading.MaybeStartReading do
  # Handler for start_reading_v1: the desk owns the business rule (a
  # reading starts once), produces the matching reading_started_v1 event,
  # and dispatches. The aggregate calls handle_from_map/2; callers
  # dispatch/1. The already-finished refusal is the aggregate's blanket
  # guard, not this desk's.
  @moduledoc false

  alias HostBookclub.ReadingAggregate
  alias HostBookclub.ReadingState
  alias HostBookclub.StartReading.{ReadingStartedV1, StartReadingV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :start_reading_v1} = payload) do
    case StartReadingV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %StartReadingV1{} = cmd) do
    case {ReadingState.in_progress?(state), StartReadingV1.validate(cmd)} do
      {true, _} ->
        {:error, :already_started}

      {false, :ok} ->
        events(cmd)

      {false, {:error, _} = error} ->
        error
    end
  end

  defp events(cmd) do
    event =
      ReadingStartedV1.new(%{
        reading_id: cmd.reading_id,
        member_id: cmd.member_id,
        book_id: cmd.book_id
      })

    case event do
      {:ok, e} -> {:ok, [ReadingStartedV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{reading_id: _reading_id} = params) do
    with {:ok, cmd} <- StartReadingV1.new(params),
         :ok <- StartReadingV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :start_reading_v1,
          ReadingAggregate,
          StartReadingV1.stream_id(cmd),
          StartReadingV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

defmodule HostBookclub.ReadingAggregate do
  # Aggregate root for one member's reading of one book.
  #
  # One stream per reading, born by start_reading_v1 and closed by
  # finish_reading_v1. The reading is the child: the member identifies it
  # (mints the reading id), the reading initiates itself with its own
  # birth event. Like every aggregate here, it owns a blanket lifecycle
  # guard: every command on a finished stream is refused before any desk
  # sees it.
  @moduledoc false

  @behaviour :evoq_aggregate

  alias HostBookclub.FinishReading.MaybeFinishReading
  alias HostBookclub.ReadingState
  alias HostBookclub.StartReading.MaybeStartReading

  @impl true
  def state_module, do: ReadingState

  @impl true
  def init(reading_id), do: {:ok, ReadingState.new(reading_id)}

  @impl true
  def apply(state, event), do: ReadingState.apply_event(state, event)

  @impl true
  def execute(state, %{command_type: :start_reading_v1} = payload) do
    guarded(state, payload, &MaybeStartReading.handle_from_map/2)
  end

  def execute(state, %{command_type: :finish_reading_v1} = payload) do
    guarded(state, payload, &MaybeFinishReading.handle_from_map/2)
  end

  def execute(_state, _payload), do: {:error, :unknown_command}

  defp guarded(state, payload, desk) do
    if ReadingState.finished?(state) do
      {:error, :finished}
    else
      desk.(state, payload)
    end
  end

  def stream_id(reading_id), do: reading_id
end

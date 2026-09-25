defmodule HostBookclub.ReadingState do
  # The reading aggregate's state: the struct, its fold, its shape.
  #
  # The state module is the only module that sees the struct. It remembers
  # the birth details (member_id, book_id, started_at), so the finished
  # event can echo them and stay self-contained for its projection -- the
  # fold a consumer needs, carried by the event instead of re-read from
  # the stream.
  @moduledoc false

  defstruct [:reading_id, :member_id, :book_id, :started_at, pages_read: 0, status: 0]

  alias HostBookclub.ReadingStatus

  def new(reading_id), do: %__MODULE__{reading_id: reading_id}

  # evoq hands apply/2 TWO SHAPES for the same event: the raw event right
  # after execute/2 (business fields inline) and the stored envelope on
  # reload (business fields under "data"). Read tolerantly.
  def apply_event(state, %{event_type: "reading_started_v1"} = event) do
    data = event_data(event)

    %{
      state
      | member_id: data["member_id"] || data[:member_id],
        book_id: data["book_id"] || data[:book_id],
        started_at: data["started_at"] || data[:started_at] || 0,
        status: :evoq_bit_flags.set(state.status, ReadingStatus.in_progress())
    }
  end

  def apply_event(state, %{event_type: "reading_finished_v1"} = event) do
    data = event_data(event)

    %{
      state
      | pages_read: data["pages_read"] || data[:pages_read] || 0,
        status: :evoq_bit_flags.set(state.status, ReadingStatus.finished())
    }
  end

  def apply_event(state, _event), do: state

  def in_progress?(state), do: :evoq_bit_flags.has(state.status, ReadingStatus.in_progress())
  def finished?(state), do: :evoq_bit_flags.has(state.status, ReadingStatus.finished())
  def status(state), do: state.status

  defp event_data(%{data: data}), do: data
  defp event_data(event), do: event
end

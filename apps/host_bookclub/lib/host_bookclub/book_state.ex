defmodule HostBookclub.BookState do
  # The book aggregate's state: the struct, its fold, its shape.
  #
  # The state module is the only module that sees the struct. It remembers
  # the birth details (club_id, title, author, procured_at, club_name), so
  # the retired event can echo them and stay self-contained for its
  # projection.
  @moduledoc false

  defstruct [:book_id, :club_id, :title, :author, :procured_at, :club_name, status: 0]

  alias HostBookclub.BookStatus

  def new(book_id), do: %__MODULE__{book_id: book_id}

  # evoq hands apply/2 TWO SHAPES for the same event: the raw event right
  # after execute/2 (business fields inline) and the stored envelope on
  # reload (business fields under "data"). Read tolerantly.
  def apply_event(state, %{event_type: "book_procured_v1"} = event) do
    data = event_data(event)

    %{
      state
      | club_id: data["club_id"] || data[:club_id],
        title: data["title"] || data[:title],
        author: data["author"] || data[:author],
        procured_at: data["procured_at"] || data[:procured_at] || 0,
        club_name: data["club_name"] || data[:club_name] || "",
        status: :evoq_bit_flags.set(state.status, BookStatus.on_shelf())
    }
  end

  def apply_event(state, %{event_type: "book_retired_v1"}) do
    %{state | status: :evoq_bit_flags.set(state.status, BookStatus.retired())}
  end

  def apply_event(state, _event), do: state

  def on_shelf?(state), do: :evoq_bit_flags.has(state.status, BookStatus.on_shelf())
  def retired?(state), do: :evoq_bit_flags.has(state.status, BookStatus.retired())
  def status(state), do: state.status

  defp event_data(%{data: data}), do: data
  defp event_data(event), do: event
end

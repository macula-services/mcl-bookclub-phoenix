defmodule HostBookclub.BookAggregate do
  # Aggregate root for a book on the club's shelf.
  #
  # One stream per book, born by procure_book_v1 and soft-deleted by
  # retire_book_v1. Like the club and the member, the aggregate owns a
  # blanket lifecycle guard: every command on a retired stream is refused
  # before any desk sees it.
  @moduledoc false

  @behaviour :evoq_aggregate

  alias HostBookclub.BookState
  alias HostBookclub.ProcureBook.MaybeProcureBook
  alias HostBookclub.RetireBook.MaybeRetireBook

  @impl true
  def state_module, do: BookState

  @impl true
  def init(book_id), do: {:ok, BookState.new(book_id)}

  @impl true
  def apply(state, event), do: BookState.apply_event(state, event)

  @impl true
  def execute(state, %{command_type: :procure_book_v1} = payload) do
    guarded(state, payload, &MaybeProcureBook.handle_from_map/2)
  end

  def execute(state, %{command_type: :retire_book_v1} = payload) do
    guarded(state, payload, &MaybeRetireBook.handle_from_map/2)
  end

  def execute(_state, _payload), do: {:error, :unknown_command}

  defp guarded(state, payload, desk) do
    if BookState.retired?(state) do
      {:error, :retired}
    else
      desk.(state, payload)
    end
  end

  def stream_id(book_id), do: book_id
end

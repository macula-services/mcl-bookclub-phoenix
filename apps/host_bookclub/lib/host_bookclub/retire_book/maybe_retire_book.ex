defmodule HostBookclub.RetireBook.MaybeRetireBook do
  # Handler for retire_book_v1: the desk owns the business rule (a book
  # retires only once it is on the shelf), produces the matching
  # book_retired_v1 event, and dispatches. The aggregate calls
  # handle_from_map/2; callers dispatch/1. The already-retired refusal is
  # the aggregate's blanket guard, not this desk's.
  @moduledoc false

  alias HostBookclub.BookAggregate
  alias HostBookclub.BookState
  alias HostBookclub.RetireBook.{BookRetiredV1, RetireBookV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :retire_book_v1} = payload) do
    case RetireBookV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %RetireBookV1{} = cmd) do
    case {BookState.on_shelf?(state), RetireBookV1.validate(cmd)} do
      {false, _} ->
        {:error, :not_procured}

      {true, :ok} ->
        events(state, cmd)

      {true, {:error, _} = error} ->
        error
    end
  end

  defp events(state, cmd) do
    event =
      BookRetiredV1.new(%{
        book_id: state.book_id,
        club_id: state.club_id,
        title: state.title,
        author: state.author,
        procured_at: state.procured_at,
        club_name: state.club_name,
        retired_by: cmd.retired_by
      })

    case event do
      {:ok, e} -> {:ok, [BookRetiredV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{book_id: _book_id} = params) do
    with {:ok, cmd} <- RetireBookV1.new(params),
         :ok <- RetireBookV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :retire_book_v1,
          BookAggregate,
          RetireBookV1.stream_id(cmd),
          RetireBookV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

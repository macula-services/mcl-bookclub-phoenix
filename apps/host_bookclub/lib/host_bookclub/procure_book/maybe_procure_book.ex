defmodule HostBookclub.ProcureBook.MaybeProcureBook do
  # Handler for procure_book_v1: the desk owns the business rule (a book
  # is procured once), produces the matching book_procured_v1 event, and
  # dispatches. The aggregate calls handle_from_map/2; callers dispatch/1.
  # The already-retired refusal is the aggregate's blanket guard, not this
  # desk's.
  @moduledoc false

  alias HostBookclub.BookAggregate
  alias HostBookclub.BookState
  alias HostBookclub.ProcureBook.{BookProcuredV1, ProcureBookV1}

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :procure_book_v1} = payload) do
    case ProcureBookV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %ProcureBookV1{} = cmd) do
    case {BookState.on_shelf?(state), ProcureBookV1.validate(cmd)} do
      {true, _} ->
        {:error, :already_procured}

      {false, :ok} ->
        events(cmd)

      {false, {:error, _} = error} ->
        error
    end
  end

  defp events(cmd) do
    event =
      BookProcuredV1.new(%{
        book_id: cmd.book_id,
        club_id: cmd.club_id,
        title: cmd.title,
        author: cmd.author,
        club_name: cmd.club_name
      })

    case event do
      {:ok, e} -> {:ok, [BookProcuredV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{book_id: _book_id} = params) do
    with {:ok, cmd} <- ProcureBookV1.new(params),
         :ok <- ProcureBookV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :procure_book_v1,
          BookAggregate,
          ProcureBookV1.stream_id(cmd),
          ProcureBookV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

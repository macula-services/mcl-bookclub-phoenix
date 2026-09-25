defmodule HostBookclub.ArchiveBookclub.MaybeArchiveBookclub do
  # Handler for archive_bookclub_v1: the desk owns the business rule (a
  # club archives only after it exists), produces the matching
  # bookclub_archived_v1 event, and dispatches. The aggregate calls
  # handle_from_map/2; callers dispatch/1.
  #
  # The already-archived refusal is NOT here: the aggregate's blanket
  # lifecycle guard owns it and returns {:error, :archived} for every
  # command on an archived stream before any desk sees it, so a check here
  # would be dead code.
  #
  # The event echoes the club's birth details from the aggregate state, so
  # the projection stays a self-sufficient absolute write -- see
  # BookclubArchivedV1's moduledoc for why that matters.
  @moduledoc false

  alias HostBookclub.ArchiveBookclub.{ArchiveBookclubV1, BookclubArchivedV1}
  alias HostBookclub.BookclubAggregate
  alias HostBookclub.BookclubState

  @store_id :mcl_bookclub_store

  def handle_from_map(state, %{command_type: :archive_bookclub_v1} = payload) do
    case ArchiveBookclubV1.from_map(payload) do
      {:ok, cmd} -> handle(state, cmd)
      {:error, _} = error -> error
    end
  end

  def handle_from_map(_state, _payload), do: {:error, :unknown_command}

  def handle(state, %ArchiveBookclubV1{} = cmd) do
    case {BookclubState.initiated?(state), ArchiveBookclubV1.validate(cmd)} do
      {false, _} ->
        {:error, :not_initiated}

      {true, :ok} ->
        events(state, cmd)

      {true, {:error, _} = error} ->
        error
    end
  end

  defp events(state, cmd) do
    event =
      BookclubArchivedV1.new(%{
        club_id: state.club_id,
        name: state.name,
        initiated_by: state.initiated_by,
        initiated_at: state.initiated_at,
        archived_by: cmd.archived_by
      })

    case event do
      {:ok, e} -> {:ok, [BookclubArchivedV1.to_map(e)]}
      {:error, _} = error -> error
    end
  end

  # VALIDATE BEFORE DISPATCH -- the store client RAISES on a bad stream id,
  # so the desk is the boundary (the corpus's Demon 67, in Elixir).
  def dispatch(%{club_id: _club_id} = params) do
    with {:ok, cmd} <- ArchiveBookclubV1.new(params),
         :ok <- ArchiveBookclubV1.validate(cmd) do
      evoq_cmd =
        :evoq_command.new(
          :archive_bookclub_v1,
          BookclubAggregate,
          ArchiveBookclubV1.stream_id(cmd),
          ArchiveBookclubV1.to_map(cmd)
        )

      :evoq_command_router.dispatch(evoq_cmd, %{
        store_id: @store_id,
        adapter: :reckon_evoq_adapter,
        consistency: :eventual
      })
    end
  end
end

defmodule HostBookclub.BookclubState do
  # The bookclub aggregate's state: the struct, its fold, its shape.
  #
  # The state module is the only module that sees the struct. It remembers
  # the birth details (name, initiated_by, initiated_at), so later events
  # can echo them -- the same self-contained-fact discipline as the Erlang
  # bookclub. It also keeps the party tally, so the planned event can
  # carry the club's NEW count as an absolute assignment, never a
  # relative "+1" a consumer would have to apply.
  @moduledoc false

  defstruct [:club_id, :name, :initiated_by, :initiated_at, parties_planned: 0, status: 0]

  alias HostBookclub.BookclubStatus

  def new(club_id), do: %__MODULE__{club_id: club_id}

  # evoq hands apply/2 TWO SHAPES for the same event: the raw event right
  # after execute/2 (business fields inline) and the stored envelope on
  # reload (business fields under "data"). Read tolerantly -- matching one
  # shape only is a bug that shows on the second command, never the first.
  def apply_event(state, %{event_type: "bookclub_initiated_v1"} = event) do
    data = event_data(event)

    %{
      state
      | name: data["name"] || data[:name],
        initiated_by: data["initiated_by"] || data[:initiated_by],
        initiated_at: data["initiated_at"] || data[:initiated_at] || 0,
        status: :evoq_bit_flags.set(state.status, BookclubStatus.initiated())
    }
  end

  def apply_event(state, %{event_type: "bookclub_archived_v1"}) do
    %{state | status: :evoq_bit_flags.set(state.status, BookclubStatus.archived())}
  end

  def apply_event(state, %{event_type: "party_planned_v1"} = event) do
    data = event_data(event)

    %{state | parties_planned: data["parties_planned"] || data[:parties_planned] || 0}
  end

  def apply_event(state, _event), do: state

  def initiated?(state), do: :evoq_bit_flags.has(state.status, BookclubStatus.initiated())
  def archived?(state), do: :evoq_bit_flags.has(state.status, BookclubStatus.archived())
  def status(state), do: state.status

  defp event_data(%{data: data}), do: data
  defp event_data(event), do: event
end

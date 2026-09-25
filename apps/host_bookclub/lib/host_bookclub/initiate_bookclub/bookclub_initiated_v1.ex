defmodule HostBookclub.InitiateBookclub.BookclubInitiatedV1 do
  # The bookclub_initiated_v1 event: a fact about the past.
  #
  # Past tense, business verb, _v1 suffix. event_type/0 returns a BINARY --
  # what evoq_event_handler's interested_in/0 matches on, whatever the
  # behaviour spec's atom says.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:club_id, :name, :initiated_by, :initiated_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "bookclub_initiated_v1"

  @impl true
  def new(%{club_id: club_id, name: name, initiated_by: by})
      when is_binary(club_id) and is_binary(name) and is_binary(by) do
    {:ok,
     %__MODULE__{club_id: club_id, name: name, initiated_by: by,
                 initiated_at: System.system_time(:millisecond)}}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{event_type: event_type(), club_id: event.club_id, name: event.name,
      initiated_by: event.initiated_by, initiated_at: event.initiated_at}
  end
end

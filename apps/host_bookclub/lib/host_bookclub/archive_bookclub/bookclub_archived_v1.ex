defmodule HostBookclub.ArchiveBookclub.BookclubArchivedV1 do
  # The bookclub_archived_v1 event: a fact about the past.
  #
  # SELF-CONTAINED, DELIBERATELY: it echoes name, initiated_by and
  # initiated_at from the aggregate state, so its projection can rebuild
  # the whole clubs row from this event alone and stay an idempotent,
  # absolute write. The alternative -- a projection UPDATE that assumes
  # the initiated event arrived first -- breaks silently the day a
  # projection is added after history exists. The house rule: if an event
  # is too poor for its consumers, enrich it at the source.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:club_id, :name, :initiated_by, :initiated_at, :archived_by, :archived_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "bookclub_archived_v1"

  @impl true
  def new(%{club_id: club_id, name: name, initiated_by: by, initiated_at: at, archived_by: who})
      when is_binary(club_id) and is_binary(name) and is_binary(by) and
             is_integer(at) and is_binary(who) do
    {:ok,
     %__MODULE__{
       club_id: club_id,
       name: name,
       initiated_by: by,
       initiated_at: at,
       archived_by: who,
       archived_at: System.system_time(:millisecond)
     }}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{
      event_type: event_type(),
      club_id: event.club_id,
      name: event.name,
      initiated_by: event.initiated_by,
      initiated_at: event.initiated_at,
      archived_by: event.archived_by,
      archived_at: event.archived_at
    }
  end
end

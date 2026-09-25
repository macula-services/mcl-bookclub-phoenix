defmodule HostBookclub.FinishReading.ReadingFinishedV1 do
  # The reading_finished_v1 event: a fact about the past.
  #
  # SELF-CONTAINED, like every soft-delete event here: it echoes the
  # member, the book and the start time from the aggregate state, so its
  # projection can fold the readings row from this event alone -- an
  # absolute, idempotent write that never depends on the started event
  # having arrived first.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:reading_id, :member_id, :book_id, :started_at, :pages_read, :finished_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "reading_finished_v1"

  @impl true
  def new(%{
        reading_id: reading_id,
        member_id: member_id,
        book_id: book_id,
        started_at: at,
        pages_read: pages
      })
      when is_binary(reading_id) and is_binary(member_id) and is_binary(book_id) and
             is_integer(at) and is_integer(pages) and pages >= 0 do
    {:ok,
     %__MODULE__{
       reading_id: reading_id,
       member_id: member_id,
       book_id: book_id,
       started_at: at,
       pages_read: pages,
       finished_at: System.system_time(:millisecond)
     }}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{
      event_type: event_type(),
      reading_id: event.reading_id,
      member_id: event.member_id,
      book_id: event.book_id,
      started_at: event.started_at,
      pages_read: event.pages_read,
      finished_at: event.finished_at
    }
  end
end

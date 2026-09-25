defmodule HostBookclub.StartReading.ReadingStartedV1 do
  # The reading_started_v1 event: a fact about the past.
  #
  # Self-contained: it carries the member and the book being read, so any
  # downstream consumer reads one event and knows everything it needs.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:reading_id, :member_id, :book_id, :started_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "reading_started_v1"

  @impl true
  def new(%{reading_id: reading_id, member_id: member_id, book_id: book_id})
      when is_binary(reading_id) and is_binary(member_id) and is_binary(book_id) do
    {:ok,
     %__MODULE__{
       reading_id: reading_id,
       member_id: member_id,
       book_id: book_id,
       started_at: System.system_time(:millisecond)
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
      started_at: event.started_at
    }
  end
end

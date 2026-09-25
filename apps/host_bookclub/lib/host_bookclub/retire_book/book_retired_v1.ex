defmodule HostBookclub.RetireBook.BookRetiredV1 do
  # The book_retired_v1 event: a fact about the past.
  #
  # SELF-CONTAINED, like the club's archived and the member's unregistered
  # events: it echoes the bibliographic facts from the aggregate state, so
  # its projection stays an absolute, idempotent write that never depends
  # on the procured event having arrived first.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [
    :book_id,
    :club_id,
    :title,
    :author,
    :procured_at,
    :club_name,
    :retired_by,
    :retired_at
  ]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "book_retired_v1"

  @impl true
  def new(
        %{
          book_id: book_id,
          club_id: club_id,
          title: title,
          author: author,
          procured_at: at,
          retired_by: by
        } = params
      )
      when is_binary(book_id) and is_binary(club_id) and is_binary(title) and
             is_binary(author) and is_integer(at) and is_binary(by) do
    {:ok,
     %__MODULE__{
       book_id: book_id,
       club_id: club_id,
       title: title,
       author: author,
       procured_at: at,
       club_name: Map.get(params, :club_name, ""),
       retired_by: by,
       retired_at: System.system_time(:millisecond)
     }}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def to_map(%__MODULE__{} = event) do
    %{
      event_type: event_type(),
      book_id: event.book_id,
      club_id: event.club_id,
      title: event.title,
      author: event.author,
      procured_at: event.procured_at,
      club_name: event.club_name,
      retired_by: event.retired_by,
      retired_at: event.retired_at
    }
  end
end

defmodule HostBookclub.ProcureBook.BookProcuredV1 do
  # The book_procured_v1 event: a fact about the past.
  #
  # Self-contained: it carries the club and the bibliographic facts, so
  # any downstream consumer reads one event and knows everything it needs.
  @moduledoc false

  @behaviour :evoq_event

  defstruct [:book_id, :club_id, :title, :author, :club_name, :procured_at]

  @type t :: %__MODULE__{}

  @impl true
  def event_type, do: "book_procured_v1"

  @impl true
  def new(%{book_id: book_id, club_id: club_id, title: title, author: author} = params)
      when is_binary(book_id) and is_binary(club_id) and is_binary(title) and
             is_binary(author) do
    {:ok,
     %__MODULE__{
       book_id: book_id,
       club_id: club_id,
       title: title,
       author: author,
       club_name: Map.get(params, :club_name, ""),
       procured_at: System.system_time(:millisecond)
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
      club_name: event.club_name,
      procured_at: event.procured_at
    }
  end
end

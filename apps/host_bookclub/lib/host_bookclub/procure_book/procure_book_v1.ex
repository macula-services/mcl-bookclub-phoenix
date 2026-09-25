defmodule HostBookclub.ProcureBook.ProcureBookV1 do
  # The procure_book_v1 command: the club acquires a book for its shelf.
  #
  # `procure', the business verb for acquisition -- never add. The command
  # names the book's stream id (minted), the club, and the bibliographic
  # facts.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:book_id, :club_id, :title, :author, club_name: ""]

  @type t :: %__MODULE__{
          book_id: binary(),
          club_id: binary(),
          title: binary(),
          author: binary(),
          club_name: binary()
        }

  @impl true
  def command_type, do: :procure_book_v1

  # Mint the book's stream id. The AggregateId IS the reckon stream id
  # (`^[a-z]{1,32}-[a-f0-9]{32}$'), so the title goes in the payload and
  # this derived id is what the command is addressed to.
  def mint_book_id, do: :reckon_gater_stream_id.new("book")

  @impl true
  def new(%{book_id: book_id, club_id: club_id, title: title, author: author} = params)
      when is_binary(book_id) and book_id != "" and is_binary(club_id) and club_id != "" and
             is_binary(title) and title != "" and is_binary(author) and author != "" do
    {:ok,
     %__MODULE__{
       book_id: book_id,
       club_id: club_id,
       title: title,
       author: author,
       club_name: Map.get(params, :club_name, "")
     }}
  end

  def new(%{book_id: _, club_id: _, title: _, author: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  # Checks about the world, not the shape: both stream ids must satisfy
  # the reckon-db stream contract.
  @impl true
  def validate(%__MODULE__{book_id: book_id, club_id: club_id}) do
    case {:reckon_gater_stream_id.validate(book_id), :reckon_gater_stream_id.validate(club_id)} do
      {:ok, :ok} ->
        :ok

      {{:error, reason}, _} ->
        {:error, reason}

      {_, {:error, reason}} ->
        {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{
      command_type: command_type(),
      book_id: cmd.book_id,
      club_id: cmd.club_id,
      title: cmd.title,
      author: cmd.author,
      club_name: cmd.club_name
    }
  end

  @impl true
  def from_map(%{book_id: book_id, club_id: club_id, title: title, author: author} = map) do
    new(%{
      book_id: book_id,
      club_id: club_id,
      title: title,
      author: author,
      club_name: map[:club_name] || ""
    })
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the book's own id.
  def stream_id(%__MODULE__{book_id: book_id}), do: book_id
end

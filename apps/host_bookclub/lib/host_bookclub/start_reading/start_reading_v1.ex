defmodule HostBookclub.StartReading.StartReadingV1 do
  # The start_reading_v1 command: a member starts reading a book.
  #
  # The reading is the child aggregate: the member's side identifies it
  # (the reading id is minted here), and the reading initiates itself with
  # its own birth event. The command carries the member and the book being
  # read -- the parents the reading refers to.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:reading_id, :member_id, :book_id]

  @type t :: %__MODULE__{reading_id: binary(), member_id: binary(), book_id: binary()}

  @impl true
  def command_type, do: :start_reading_v1

  # Mint the reading's stream id. The AggregateId IS the reckon stream id,
  # so the parents go in the payload and this derived id is what the
  # command is addressed to.
  def mint_reading_id, do: :reckon_gater_stream_id.new("reading")

  @impl true
  def new(%{reading_id: reading_id, member_id: member_id, book_id: book_id})
      when is_binary(reading_id) and reading_id != "" and is_binary(member_id) and
             member_id != "" and is_binary(book_id) and book_id != "" do
    {:ok, %__MODULE__{reading_id: reading_id, member_id: member_id, book_id: book_id}}
  end

  def new(%{reading_id: _, member_id: _, book_id: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  # Checks about the world, not the shape: every stream id must satisfy
  # the reckon-db stream contract.
  @impl true
  def validate(%__MODULE__{reading_id: reading_id, member_id: member_id, book_id: book_id}) do
    case {:reckon_gater_stream_id.validate(reading_id),
          :reckon_gater_stream_id.validate(member_id),
          :reckon_gater_stream_id.validate(book_id)} do
      {:ok, :ok, :ok} ->
        :ok

      {{:error, reason}, _, _} ->
        {:error, reason}

      {_, {:error, reason}, _} ->
        {:error, reason}

      {_, _, {:error, reason}} ->
        {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{
      command_type: command_type(),
      reading_id: cmd.reading_id,
      member_id: cmd.member_id,
      book_id: cmd.book_id
    }
  end

  @impl true
  def from_map(%{reading_id: reading_id, member_id: member_id, book_id: book_id}) do
    new(%{reading_id: reading_id, member_id: member_id, book_id: book_id})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the reading's own id.
  def stream_id(%__MODULE__{reading_id: reading_id}), do: reading_id
end

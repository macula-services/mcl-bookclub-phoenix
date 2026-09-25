defmodule HostBookclub.RetireBook.RetireBookV1 do
  # The retire_book_v1 command: soft-delete the book.
  #
  # `retire', the shelf-domain verb for a book leaving the shelf -- never
  # delete. Everything else the retired event needs comes from the
  # aggregate state, echoed into the event.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:book_id, :retired_by]

  @type t :: %__MODULE__{book_id: binary(), retired_by: binary()}

  @impl true
  def command_type, do: :retire_book_v1

  @impl true
  def new(%{book_id: book_id, retired_by: by})
      when is_binary(book_id) and book_id != "" and is_binary(by) and by != "" do
    {:ok, %__MODULE__{book_id: book_id, retired_by: by}}
  end

  def new(%{book_id: _, retired_by: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def validate(%__MODULE__{book_id: book_id}) do
    case :reckon_gater_stream_id.validate(book_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{command_type: command_type(), book_id: cmd.book_id, retired_by: cmd.retired_by}
  end

  @impl true
  def from_map(%{book_id: book_id, retired_by: by}) do
    new(%{book_id: book_id, retired_by: by})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the book's own id.
  def stream_id(%__MODULE__{book_id: book_id}), do: book_id
end

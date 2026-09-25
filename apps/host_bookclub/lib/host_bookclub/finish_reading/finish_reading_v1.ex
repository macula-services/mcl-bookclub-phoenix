defmodule HostBookclub.FinishReading.FinishReadingV1 do
  # The finish_reading_v1 command: a member finishes reading a book.
  #
  # The command names the reading's stream id and the pages read.
  # Everything else the finished event needs comes from the aggregate
  # state, echoed into the event.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:reading_id, :pages_read]

  @type t :: %__MODULE__{reading_id: binary(), pages_read: non_neg_integer()}

  @impl true
  def command_type, do: :finish_reading_v1

  @impl true
  def new(%{reading_id: reading_id, pages_read: pages})
      when is_binary(reading_id) and reading_id != "" and is_integer(pages) and pages >= 0 do
    {:ok, %__MODULE__{reading_id: reading_id, pages_read: pages}}
  end

  def new(%{reading_id: _, pages_read: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def validate(%__MODULE__{reading_id: reading_id}) do
    case :reckon_gater_stream_id.validate(reading_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{command_type: command_type(), reading_id: cmd.reading_id, pages_read: cmd.pages_read}
  end

  @impl true
  def from_map(%{reading_id: reading_id, pages_read: pages}) do
    new(%{reading_id: reading_id, pages_read: pages})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the reading's own id.
  def stream_id(%__MODULE__{reading_id: reading_id}), do: reading_id
end

defmodule HostBookclub.ArchiveBookclub.ArchiveBookclubV1 do
  # The archive_bookclub_v1 command: soft-delete the club.
  #
  # `archive', the house soft-delete verb -- never delete. The command
  # names the club's stream id and who archived it; everything else the
  # archive needs comes from the aggregate state, echoed into the event.
  # The payload keys are ATOMS -- evoq reads command_type with an atom
  # lookup.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:club_id, :archived_by]

  @type t :: %__MODULE__{club_id: binary(), archived_by: binary()}

  @impl true
  def command_type, do: :archive_bookclub_v1

  @impl true
  def new(%{club_id: club_id, archived_by: by})
      when is_binary(club_id) and club_id != "" and is_binary(by) and by != "" do
    {:ok, %__MODULE__{club_id: club_id, archived_by: by}}
  end

  def new(%{club_id: _, archived_by: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  # Checks about the world, not the shape: the stream id must satisfy the
  # reckon contract, or the append is refused.
  @impl true
  def validate(%__MODULE__{club_id: club_id}) do
    case :reckon_gater_stream_id.validate(club_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{command_type: command_type(), club_id: cmd.club_id, archived_by: cmd.archived_by}
  end

  @impl true
  def from_map(%{club_id: club_id, archived_by: by}) do
    new(%{club_id: club_id, archived_by: by})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the club's own id.
  def stream_id(%__MODULE__{club_id: club_id}), do: club_id
end

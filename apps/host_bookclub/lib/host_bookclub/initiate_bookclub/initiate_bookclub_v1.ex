defmodule HostBookclub.InitiateBookclub.InitiateBookclubV1 do
  # The initiate_bookclub_v1 command: what a caller asks for.
  #
  # A struct with a to_map/1 that becomes the payload the aggregate's
  # execute/2 sees. The payload keys are ATOMS -- evoq reads command_type
  # with an atom lookup. The club's stream id IS its identity, minted
  # here, never derived from the human name.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:club_id, :name, :initiated_by]

  @type t :: %__MODULE__{club_id: binary(), name: binary(), initiated_by: binary()}

  @impl true
  def command_type, do: :initiate_bookclub_v1

  # Mint the club's stream id: reckon's contract is
  # `^[a-z]{1,32}-[a-f0-9]{32}$', so the human name goes in the payload.
  def mint_club_id, do: :reckon_gater_stream_id.new("bookclub")

  @impl true
  def new(%{club_id: club_id, name: name, initiated_by: by})
      when is_binary(club_id) and club_id != "" and is_binary(name) and name != "" and
             is_binary(by) and by != "" do
    {:ok, %__MODULE__{club_id: club_id, name: name, initiated_by: by}}
  end

  def new(%{club_id: _, name: _, initiated_by: _}), do: {:error, :invalid_params}
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
    %{command_type: command_type(), club_id: cmd.club_id, name: cmd.name,
      initiated_by: cmd.initiated_by}
  end

  @impl true
  def from_map(%{club_id: club_id, name: name, initiated_by: by} = map) do
    new(%{club_id: club_id, name: name, initiated_by: by, club_name: map[:club_name] || ""})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  def stream_id(%__MODULE__{club_id: club_id}), do: club_id
end

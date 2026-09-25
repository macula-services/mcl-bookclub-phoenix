defmodule HostBookclub.RegisterMember.RegisterMemberV1 do
  # The register_member_v1 command: a person joins the club.
  #
  # The command names the member's stream id (minted, never derived from
  # the human name), the club being joined, and the member's name. The
  # payload keys are ATOMS -- evoq reads command_type with an atom lookup.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:member_id, :club_id, :name, club_name: ""]

  @type t :: %__MODULE__{
          member_id: binary(),
          club_id: binary(),
          name: binary(),
          club_name: binary()
        }

  @impl true
  def command_type, do: :register_member_v1

  # Mint the member's stream id. The AggregateId IS the reckon stream id
  # (`^[a-z]{1,32}-[a-f0-9]{32}$'), so the human name goes in the payload
  # and this derived id is what the command is addressed to. Never
  # hand-roll the suffix; reckon_gater_stream_id:new/1 mints the contract.
  def mint_member_id, do: :reckon_gater_stream_id.new("member")

  @impl true
  def new(%{member_id: member_id, club_id: club_id, name: name} = params)
      when is_binary(member_id) and member_id != "" and is_binary(club_id) and club_id != "" and
             is_binary(name) and name != "" do
    {:ok,
     %__MODULE__{
       member_id: member_id,
       club_id: club_id,
       name: name,
       club_name: Map.get(params, :club_name, "")
     }}
  end

  def new(%{member_id: _, club_id: _, name: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  # Checks about the world, not the shape: both stream ids must satisfy
  # the reckon-db stream contract.
  @impl true
  def validate(%__MODULE__{member_id: member_id, club_id: club_id}) do
    case {:reckon_gater_stream_id.validate(member_id), :reckon_gater_stream_id.validate(club_id)} do
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
      member_id: cmd.member_id,
      club_id: cmd.club_id,
      name: cmd.name,
      club_name: cmd.club_name
    }
  end

  @impl true
  def from_map(%{member_id: member_id, club_id: club_id, name: name} = map) do
    new(%{member_id: member_id, club_id: club_id, name: name, club_name: map[:club_name] || ""})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the member's own id.
  def stream_id(%__MODULE__{member_id: member_id}), do: member_id
end

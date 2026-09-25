defmodule HostBookclub.PlanParty.PlanPartyV1 do
  # The plan_party_v1 command: the club plans a party.
  #
  # The command names the club's stream id and nothing else -- the party
  # count lives in the aggregate state, incremented there and echoed into
  # the event.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:club_id]

  @type t :: %__MODULE__{club_id: binary()}

  @impl true
  def command_type, do: :plan_party_v1

  @impl true
  def new(%{club_id: club_id}) when is_binary(club_id) and club_id != "" do
    {:ok, %__MODULE__{club_id: club_id}}
  end

  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def validate(%__MODULE__{club_id: club_id}) do
    case :reckon_gater_stream_id.validate(club_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{command_type: command_type(), club_id: cmd.club_id}
  end

  @impl true
  def from_map(%{club_id: club_id}) do
    new(%{club_id: club_id})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the club's own id.
  def stream_id(%__MODULE__{club_id: club_id}), do: club_id
end

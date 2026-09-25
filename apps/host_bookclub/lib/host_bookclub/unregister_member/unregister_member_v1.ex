defmodule HostBookclub.UnregisterMember.UnregisterMemberV1 do
  # The unregister_member_v1 command: soft-delete the member.
  #
  # `unregister', the club-domain verb for a member leaving -- never
  # delete. Everything else the unregistered event needs comes from the
  # aggregate state, echoed into the event.
  @moduledoc false

  @behaviour :evoq_command

  defstruct [:member_id, :unregistered_by]

  @type t :: %__MODULE__{member_id: binary(), unregistered_by: binary()}

  @impl true
  def command_type, do: :unregister_member_v1

  @impl true
  def new(%{member_id: member_id, unregistered_by: by})
      when is_binary(member_id) and member_id != "" and is_binary(by) and by != "" do
    {:ok, %__MODULE__{member_id: member_id, unregistered_by: by}}
  end

  def new(%{member_id: _, unregistered_by: _}), do: {:error, :invalid_params}
  def new(_), do: {:error, :missing_required_fields}

  @impl true
  def validate(%__MODULE__{member_id: member_id}) do
    case :reckon_gater_stream_id.validate(member_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def to_map(%__MODULE__{} = cmd) do
    %{
      command_type: command_type(),
      member_id: cmd.member_id,
      unregistered_by: cmd.unregistered_by
    }
  end

  @impl true
  def from_map(%{member_id: member_id, unregistered_by: by}) do
    new(%{member_id: member_id, unregistered_by: by})
  end

  def from_map(_), do: {:error, :missing_required_fields}

  # The stream the command is addressed to: the member's own id.
  def stream_id(%__MODULE__{member_id: member_id}), do: member_id
end

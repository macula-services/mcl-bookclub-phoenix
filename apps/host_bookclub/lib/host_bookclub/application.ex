defmodule HostBookclub.Application do
  # OTP application entry for the CMD division. Aggregates are started on
  # demand by evoq; the policies and emitters land here as supervised
  # evoq_event_handler children in later slices.
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: HostBookclub.Supervisor)
  end
end

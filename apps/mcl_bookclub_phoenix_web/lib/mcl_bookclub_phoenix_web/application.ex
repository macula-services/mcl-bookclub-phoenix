defmodule MclBookclubPhoenixWeb.Application do
  # This app only starts the Endpoint. The MclBookclubPhoenixWeb.PubSub
  # registry itself is started by ProjectBookclub, NOT here -- see that
  # app's Supervisor for why (the writer side owning the registry makes a
  # cold-boot broadcast race impossible by construction). LiveViews
  # subscribe and react; their task buttons dispatch through the
  # divisions' entry points, which is the one sanctioned path from
  # presentation to business -- see macula-io/CLAUDE.md's "Phoenix
  # LiveView Architecture" rule.
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [MclBookclubPhoenixWeb.Endpoint]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: MclBookclubPhoenixWeb.Supervisor
    )
  end

  @impl true
  def config_change(changed, _new, removed) do
    MclBookclubPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

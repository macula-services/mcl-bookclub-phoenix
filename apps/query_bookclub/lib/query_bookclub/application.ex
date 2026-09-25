defmodule QueryBookclub.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [{QueryBookclub.BookclubQueryStore, nil}]
    Supervisor.start_link(children, strategy: :one_for_one, name: QueryBookclub.Supervisor)
  end
end

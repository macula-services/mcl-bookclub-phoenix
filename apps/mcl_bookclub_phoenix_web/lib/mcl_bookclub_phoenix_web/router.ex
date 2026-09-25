defmodule MclBookclubPhoenixWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, html: {MclBookclubPhoenixWeb.Layouts, :root})
  end

  scope "/", MclBookclubPhoenixWeb do
    pipe_through(:browser)

    live("/", AdminLive)
  end
end

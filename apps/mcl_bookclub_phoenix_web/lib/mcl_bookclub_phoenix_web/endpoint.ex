defmodule MclBookclubPhoenixWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mcl_bookclub_phoenix_web

  @session_options [
    store: :cookie,
    key: "_mcl_bookclub_key",
    signing_salt: "hbc_session_salt",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Only the esbuild bundle lives under priv/static; no favicon shipped
  # yet. Listing just `assets` lets a browser's routine favicon request
  # 404 cleanly instead of becoming a raw 500.
  plug(Plug.Static,
    at: "/",
    from: :mcl_bookclub_phoenix_web,
    gzip: false,
    only: ~w(assets)
  )

  plug(Plug.RequestId)
  plug(Plug.Session, @session_options)
  plug(MclBookclubPhoenixWeb.Router)
end

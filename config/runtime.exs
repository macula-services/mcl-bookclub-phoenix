import Config

# Evaluated on every boot -- dev and prod. Dev-safe defaults: a laptop boot
# proves the CMD/evoq wiring with no mesh secrets; the deployed container
# sets the real values. Fleet placement lives in macula-io/macula-fleet.
#
# A TEST run gets a FRESH store dir every time: the reckon store leaves dets
# files behind, and a second run against the same dir fails to reopen them.
data_dir =
  if Mix.env() == :test do
    Path.join(System.tmp_dir!(), "mcl_bookclub_test_#{System.unique_integer([:positive])}")
  else
    System.get_env("MCL_DATA_DIR", "/tmp/mcl_bookclub")
  end

System.put_env("MCL_DATA_DIR", data_dir)
health_port = String.to_integer(System.get_env("MCL_HEALTH_PORT", "8454"))

# THE REALM NAME IS THE ONE INPUT; THE TAG IS DERIVED FROM IT HERE.
realm_name = System.get_env("MCL_REALM_NAME", "io.macula")
realm = :crypto.hash(:sha256, realm_name) |> Base.encode16(case: :lower)

# The wire namespace -- the SAME org as the Erlang bookclub: the contract
# is shared, the club is a payload parameter.
org = "mcl-bookclub"

config :mcl_om,
  identity_key_path:
    String.to_charlist(
      System.get_env("MCL_IDENTITY_KEY_PATH", Path.join([data_dir, "identity", "identity.key"]))
    ),
  health_port: health_port,
  capability_topic: "_mesh.cap.",
  org: org,
  realm: realm,
  realm_key: System.get_env("MCL_REALM_KEY", "")

# THE PQ CRYPTO PROFILE, WITHOUT WHICH THIS NODE DOES NOT PEER.
config :macula,
  crypto_profile: :pq_hybrid

# MANDATORY because the service exports store_id/0: mcl_om:boot/1 starts
# the store and its subscription, which crash without the adapter block.
config :evoq,
  event_store_adapter: :reckon_evoq_adapter,
  subscription_adapter: :reckon_evoq_adapter,
  snapshot_store_adapter: :reckon_evoq_adapter,
  store_id: :mcl_bookclub_store

# The LAN admin console, served by the web app. LAN-facing like the
# Erlang twin's admin UI, on MCL_HTTP_PORT (default 4000) -- the Erlang
# bookclub owns 8488, so a second club on the same box needs its own.
http_port = String.to_integer(System.get_env("MCL_HTTP_PORT", "4000"))

# Signs the LiveView socket. A release REQUIRES it: a prod node that fell
# back to the fixed development value below would sign with a string
# anyone can read in this file. Dev and test get that value, which
# protects nothing and needs only to be 64+ bytes for Phoenix to accept
# it.
secret_key_base =
  if config_env() == :prod do
    System.fetch_env!("SECRET_KEY_BASE")
  else
    System.get_env(
      "SECRET_KEY_BASE",
      "hbcdev000000000000000000000000000000000000000000000000000000000000000000000000"
    )
  end

config :mcl_bookclub_phoenix_web, MclBookclubPhoenixWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: http_port],
  server: true,
  secret_key_base: secret_key_base,
  adapter: Bandit.PhoenixAdapter,
  pubsub_server: MclBookclubPhoenixWeb.PubSub,
  live_view: [signing_salt: "hbc_live_view_salt"],
  # No fronting domain yet -- this is reached directly at host:PORT (or
  # localhost in dev), so there's no single fixed :url host to check the
  # socket's Origin against. check_origin: false is a deliberate
  # simplification for the LAN admin phase (single-box operator tool, no
  # auth/multi-tenancy yet), not an oversight -- revisit once this sits
  # behind a real host/domain.
  check_origin: false

# NODE_PATH=deps lets esbuild resolve bare `import "phoenix"` /
# `import "phoenix_live_view"` against the Hex deps' own package.json
# (each ships priv/static/*.mjs) -- no npm install needed for those two.
config :esbuild,
  version: "0.25.0",
  mcl_bookclub_phoenix_web: [
    args: ~w(js/app.js --bundle --target=es2022 --outfile=../priv/static/assets/app.js),
    cd: Path.expand("../apps/mcl_bookclub_phoenix_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

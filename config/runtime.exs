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

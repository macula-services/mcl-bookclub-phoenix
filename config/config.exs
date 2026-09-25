import Config

# Compile-time config only: everything env-driven lives in config/runtime.exs,
# evaluated on every boot (dev, prod and test alike). This file is the home of
# what build tools need WITHOUT a boot: the esbuild asset profile, which
# `mix esbuild mcl_bookclub_phoenix_web` reads at build time in the
# Containerfile (a runtime.exs evaluation there would demand SECRET_KEY_BASE
# and other boot-only env).

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

# mcl-bookclub-phoenix: the Bookclub-on-Mesh in Elixir -- the drop-in twin of
# mcl-bookclub, with a Phoenix LiveView admin. A host runs this as a second
# club on the mesh; same org, same topics, same procedure names, a different
# node identity.
#
# PINNED BY DIGEST, and the SAME images CI uses, so what ships is what was
# tested. The builder is ghcr.io/macula-io/macula-ci-pq ex118 (Elixir 1.18.4 on
# OTP 28.4.3, Hex and rebar3 pinned, Rust for macula's NIFs), the exact image
# .github/workflows/ci.yml tests in. The runner is macula-pq-runtime from the
# same build (same Debian trixie date, so glibc and OpenSSL 3.5 match the
# builder's). Move all three pins together (the whiteboard owns the same pair).
#
# Elixir 1.18, not 1.19: 1.19 cannot assemble a release that carries khepri,
# because horus lists :erts among its applications (elixir-lang/elixir#15934).
ARG BUILDER_IMAGE="ghcr.io/macula-io/macula-ci-pq:ex118-20260923-1444@sha256:d61833350b8ad6e6e1aef22e833e323d0950bdc4fed33ddf7df321d2df9e1f32"
ARG RUNNER_IMAGE="ghcr.io/macula-io/macula-pq-runtime:20260923-1444@sha256:15a5501b7277804c5a62c93121d157773d1401d238a1bf630ef4b50fc2f1df09"

# =============================================================================
# BUILD STAGE
# =============================================================================
FROM ${BUILDER_IMAGE} AS builder

# The builder carries the C toolchain, cmake, OpenSSL headers, git, Rust, Hex
# and rebar3 at pinned versions; nothing is installed on top of it.
WORKDIR /app
ENV MIX_ENV=prod
# macula's QUIC NIF is compiled from source against this OTP, never fetched
# precompiled for another one.
ENV MACULA_FORCE_SOURCE_BUILD=1

# The TESTED resolve. CI hands this build the mix.lock its test job resolved (a
# workflow artifact, never committed), so deps.get fetches exactly the versions
# the tests ran on; scripts/assert_release_matches_lock.sh then checks the
# release against it. The glob keeps a local build without a lock working.
COPY mix.exs mix.lock* ./
COPY apps/host_bookclub/mix.exs ./apps/host_bookclub/
COPY apps/project_bookclub/mix.exs ./apps/project_bookclub/
COPY apps/query_bookclub/mix.exs ./apps/query_bookclub/
COPY apps/mcl_bookclub_phoenix/mix.exs ./apps/mcl_bookclub_phoenix/
COPY apps/mcl_bookclub_phoenix_web/mix.exs ./apps/mcl_bookclub_phoenix_web/
COPY config ./config

# Referenced, not just declared: an ARG only invalidates a layer whose own
# instruction uses it. Every dependency resolves through a loose constraint, so
# a rebuild on unchanged sources must still run a real deps.get.
ARG CACHE_BUST=unknown
RUN echo "cache_bust=${CACHE_BUST}" > /dev/null

RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Cache-busts /assets/app.js across a redeploy; see
# MclBookclubPhoenixWeb.BuildInfo.
ARG GIT_SHA=dev
ENV GIT_SHA=${GIT_SHA}

COPY apps ./apps
COPY rel ./rel
RUN mix compile

# app.js (phoenix + phoenix_live_view resolved against deps/, see
# config/config.exs), bundled into the web app's priv/static.
RUN mix esbuild.install --if-missing && \
    mix esbuild mcl_bookclub_phoenix_web

# +S 1: mix release copies ERTS with parallel tasks, and on overlayfs a chmod
# can race ahead of the copy. Serial assembly is deterministic.
RUN ELIXIR_ERL_OPTIONS="+S 1" mix release mcl_bookclub_phoenix

# =============================================================================
# RUNTIME STAGE
# =============================================================================
FROM ${RUNNER_IMAGE}

# LINKS THE PACKAGE TO THE REPOSITORY: a ghcr package without it is an orphan
# that does not appear on the repository page.
LABEL org.opencontainers.image.source="https://github.com/macula-services/mcl-bookclub-phoenix"

# macula-pq-runtime carries OpenSSL 3.5, libstdc++, ncurses, ca-certificates,
# curl and a UTF-8 locale; nothing is installed on top of it, so the runtime's
# packages are exactly the pinned image's.

WORKDIR /app
RUN useradd --create-home --shell /bin/bash app

# Must EXIST in the image, owned by app: a freshly created named volume takes
# its content and ownership from the path it is mounted over, so a path missing
# here becomes a root-owned volume the release cannot write.
#   /var/lib/mcl-bookclub   the club store (reckon-db) and read model
#   /etc/mcl/secrets        the node identity key
RUN mkdir -p /var/lib/mcl-bookclub /etc/mcl/secrets && \
    chown -R app:app /var/lib/mcl-bookclub /etc/mcl/secrets

COPY --from=builder --chown=app:app /app/_build/prod/rel/mcl_bookclub_phoenix ./

USER app

ENV MCL_DATA_DIR=/var/lib/mcl-bookclub
ENV MCL_IDENTITY_KEY_PATH=/etc/mcl/secrets/identity.key
ENV MCL_HEALTH_PORT=8454
ENV MCL_HTTP_PORT=4000
VOLUME ["/var/lib/mcl-bookclub", "/etc/mcl/secrets"]
EXPOSE 8454 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${MCL_HEALTH_PORT}/health" || exit 1

CMD ["bin/mcl_bookclub_phoenix", "start"]

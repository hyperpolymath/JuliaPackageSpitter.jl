# SPDX-License-Identifier: MPL-2.0
# Copyright (c) {{CURRENT_YEAR}} {{AUTHOR}} (hyperpolymath) <{{AUTHOR_EMAIL}}>
#
# Containerfile for {{PROJECT_NAME}}
# Build: podman build -t juliapackagespitter:latest -f Containerfile .
# Run:   podman run --rm -it juliapackagespitter:latest
# Seal:  selur seal juliapackagespitter:latest

# --- Build stage ---
# Pinned by digest. Provenance: this exact pin is used by
# hyperpolymath/echidna's Containerfile (three FROM lines) as of 2026-10-30 and
# was copied programmatically rather than transcribed. It is a real digest for
# cgr.dev/chainguard/wolfi-base; it was NOT resolved against the registry from
# this environment, which has no access to cgr.dev, so it should be re-resolved
# with `skopeo inspect docker://cgr.dev/chainguard/wolfi-base:latest` at the
# next maintenance pass. The tag is kept alongside the digest because the digest
# is what pins; the tag only documents intent.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c2092b053779e14c82fb50f77b37bcc38b7d2c83972352d5813280f9d035b03 AS build

# TODO: Install build dependencies for your stack
# Examples:
#   RUN apk add --no-cache rust cargo       # Rust
#   RUN apk add --no-cache elixir erlang    # Elixir
#   RUN apk add --no-cache zig              # Zig

WORKDIR /build
COPY . .

# TODO: Replace with your build command
# Examples:
#   RUN cargo build --release
#   RUN mix deps.get && MIX_ENV=prod mix release
#   RUN zig build -Doptimize=ReleaseSafe

# --- Runtime stage ---
FROM cgr.dev/chainguard/static:latest

# Copy built artifact from build stage
# TODO: Replace with your binary/artifact path
# Examples:
#   COPY --from=build /build/target/release/juliapackagespitter /usr/local/bin/
#   COPY --from=build /build/_build/prod/rel/juliapackagespitter /app/
#   COPY --from=build /build/zig-out/bin/juliapackagespitter /usr/local/bin/

# Non-root user (chainguard images default to nonroot)
USER nonroot

# TODO: Replace with your entrypoint
# ENTRYPOINT ["/usr/local/bin/juliapackagespitter"]

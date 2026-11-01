# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Containerfile for JuliaPackageSpitter.jl
# Build: podman build -t juliapackagespitter:latest -f Containerfile .
# Run:   podman run --rm -it juliapackagespitter:latest
# Seal:  selur seal juliapackagespitter:latest

# --- Build stage ---
# Pinned by digest (matching hyperpolymath/echidna and stapeln.toml).
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c2092b053779e14c82fb50f77b37bcc38b7d2c83972352d5813280f9d035b03 AS build

RUN apk add --no-cache julia git ca-certificates

WORKDIR /app
COPY Project.toml README.adoc LICENSE ./
COPY src ./src
COPY templates ./templates
COPY examples ./examples
COPY test ./test

ENV JULIA_DEPOT_PATH=/opt/julia-depot
RUN julia --project=/app -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# --- Runtime stage ---
# Pinned to the same verified wolfi-base digest as [layers.runtime] in stapeln.toml;
# Julia requires glibc/libstdc++ at runtime rather than chainguard/static.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c2092b053779e14c82fb50f77b37bcc38b7d2c83972352d5813280f9d035b03 AS runtime

RUN apk add --no-cache julia ca-certificates

ENV JULIA_DEPOT_PATH=/opt/julia-depot
WORKDIR /app
COPY --from=build --chown=nonroot:nonroot /opt/julia-depot /opt/julia-depot
COPY --from=build --chown=nonroot:nonroot /app /app

USER nonroot

ENTRYPOINT ["julia", "--project=/app"]
CMD ["examples/quickstart.jl"]

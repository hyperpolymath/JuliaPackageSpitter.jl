# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Containerfile for JuliaPackageSpitter.jl
# Build: podman build -t juliapackagespitter:latest -f Containerfile .
# Run:   podman run --rm -it juliapackagespitter:latest
# Seal:  selur seal juliapackagespitter:latest

# --- Build stage ---
# Pinned by digest (matching hyperpolymath/echidna and stapeln.toml).
# Wolfi does not ship a `julia` apk package, so we install the official
# SHA-256-verified Julia 1.10.12 Linux tarball for x86_64 or aarch64.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c2092b053779e14c82fb50f77b37bcc38b7d2c83972352d5813280f9d035b03 AS build

ARG JULIA_VERSION=1.10.12
ARG JULIA_SHA256_X86_64=b0c50dfe349d76ffc8580d24e0c0be623988a6d91ed57ad8b73c0137fd27bc0d
ARG JULIA_SHA256_AARCH64=cc257b21967049642bfe17de1aff7dae17477eba4f423f98cb400c002080e5a2

RUN apk add --no-cache ca-certificates curl git tar \
    && arch="$(uname -m)" \
    && case "${arch}" in \
        x86_64) julia_arch="x64"; julia_tar_arch="x86_64"; julia_sha="${JULIA_SHA256_X86_64}" ;; \
        aarch64) julia_arch="aarch64"; julia_tar_arch="aarch64"; julia_sha="${JULIA_SHA256_AARCH64}" ;; \
        *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://julialang-s3.julialang.org/bin/linux/${julia_arch}/1.10/julia-${JULIA_VERSION}-linux-${julia_tar_arch}.tar.gz" -o /tmp/julia.tar.gz \
    && echo "${julia_sha}  /tmp/julia.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/julia \
    && tar -xzf /tmp/julia.tar.gz -C /opt/julia --strip-components=1 \
    && rm -f /tmp/julia.tar.gz

ENV PATH="/opt/julia/bin:${PATH}"
ENV JULIA_DEPOT_PATH=/opt/julia-depot

WORKDIR /app
COPY Project.toml README.adoc LICENSE ./
COPY src ./src
COPY templates ./templates
COPY examples ./examples
COPY test ./test

RUN julia --project=/app -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# --- Runtime stage ---
# Pinned to the same verified wolfi-base digest as [layers.runtime] in stapeln.toml;
# Julia requires glibc at runtime rather than chainguard/static.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c2092b053779e14c82fb50f77b37bcc38b7d2c83972352d5813280f9d035b03 AS runtime

RUN apk add --no-cache ca-certificates

ENV PATH="/opt/julia/bin:${PATH}"
ENV JULIA_DEPOT_PATH=/opt/julia-depot

WORKDIR /app
COPY --from=build /opt/julia /opt/julia
COPY --from=build --chown=nonroot:nonroot /opt/julia-depot /opt/julia-depot
COPY --from=build --chown=nonroot:nonroot /app /app

USER nonroot

ENTRYPOINT ["julia", "--project=/app"]
CMD ["examples/quickstart.jl"]

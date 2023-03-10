FROM rust:1.65.0 AS chef
WORKDIR sui
ARG GIT_REVISION
ENV GIT_REVISION=$GIT_REVISION
RUN apt-get update && apt-get install -y cmake clang

# Plan out the 3rd-party dependencies that need to be built.
#
# This is done by:
#   1. Copy in Cargo.toml, Cargo.lock, and the workspace-hack crate
#   2. Removing all workspace crates, other than the workpsace-hack
#      crate, from the workspace Cargo.toml file.
#   3. Update the lockfile in order to reflect the changes to the
#      root Cargo.toml file.
FROM chef AS planner
COPY Cargo.toml Cargo.lock ./
COPY crates/workspace-hack crates/workspace-hack
RUN sed -i '/crates\/workspace-hack/b; /crates/d; /narwhal/d' Cargo.toml \
    && cargo metadata -q >/dev/null

# Build and cache all dependencies.
#
# In a fresh layer, copy in the "plan" generated by the planner
# and run `cargo build` in order to create a caching Docker layer
# with all dependencies built.
FROM chef AS builder 
COPY --from=planner /sui/Cargo.toml Cargo.toml
COPY --from=planner /sui/Cargo.lock Cargo.lock
COPY --from=planner /sui/crates/workspace-hack crates/workspace-hack
RUN cargo build --release

# Build application
#
# Copy in the rest of the crates (and an unmodified Cargo.toml and Cargo.lock)
# and build the application. At this point no dependencies should need to be
# built as they were built and cached by the previous layer.
COPY Cargo.toml Cargo.lock ./
COPY crates crates
COPY narwhal narwhal
RUN cargo build --release \
    --bin sui-indexer

# Production Image
FROM debian:bullseye-slim AS runtime
WORKDIR sui
COPY --from=builder /sui/target/release/sui-indexer /usr/local/bin
# sui-indexer needs postgres libpq5 and ca-certificates
RUN apt update && apt install -y libpq5 ca-certificates

ARG BUILD_DATE
ARG GIT_REVISION
LABEL build-date=$BUILD_DATE
LABEL git-revision=$GIT_REVISION
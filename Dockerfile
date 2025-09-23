# =============================================================================
# LYVOXA CONTAINERIZED BUILD - ARCH LINUX BASE
# =============================================================================
# Multi-stage Docker build for Lyvoxa system monitor
# Optimized for Linux x86_64 with CPU limits and caching
# Author: rezky_nightky
# Version: Stellar 1.5

# -----------------------------------------------------------------------------
# Stage 1: Build Environment (Arch Linux base)
# -----------------------------------------------------------------------------
FROM archlinux:latest AS builder

# Set build arguments
ARG BUILD_JOBS=3
ARG RUST_VERSION=stable
ARG TARGET=x86_64-unknown-linux-gnu

# Install system dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        curl \
        git \
        mold \
        sccache \
        && \
    pacman -Scc --noconfirm

# Create non-root user for building
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to builder user
USER builder
WORKDIR /home/builder

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain ${RUST_VERSION} \
    --target ${TARGET} \
    --component rustfmt,clippy,rust-src \
    --profile minimal \
    -y

# Add Rust to PATH
ENV PATH="/home/builder/.cargo/bin:${PATH}"

# Install sccache for caching
RUN cargo install sccache

# Set environment variables for optimized builds
ENV RUSTC_WRAPPER=sccache
ENV CARGO_INCREMENTAL=1
ENV CARGO_TARGET_DIR=/tmp/target
ENV SCCACHE_DIR=/tmp/sccache

# Create cache directories
RUN mkdir -p /tmp/target /tmp/sccache

# -----------------------------------------------------------------------------
# Stage 2: Application Build
# -----------------------------------------------------------------------------
FROM builder AS app-builder

# Set working directory
WORKDIR /app

# Copy Rust configuration files first (for better caching)
COPY --chown=builder:builder rust-toolchain.toml ./
COPY --chown=builder:builder Cargo.toml ./
COPY --chown=builder:builder Cargo.lock ./
COPY --chown=builder:builder .cargo/ ./.cargo/

# Pre-build dependencies (cache layer)
RUN mkdir src && \
    echo 'fn main() { println!("Hello, world!"); }' > src/main.rs && \
    echo 'fn main() { println!("Hello, world!"); }' > src/simple.rs && \
    if [ "${BUILD_JOBS}" = "0" ]; then \
        cargo build --target ${TARGET}; \
    else \
        cargo build --jobs ${BUILD_JOBS} --target ${TARGET}; \
    fi && \
    rm -rf src

# Copy source code
COPY --chown=builder:builder src/ ./src/

# Build the application with CPU limits (0 means use default)
RUN if [ "${BUILD_JOBS}" = "0" ]; then \
        echo "Building Lyvoxa with default CPU cores..." && \
        cargo build --release --target ${TARGET}; \
    else \
        echo "Building Lyvoxa with ${BUILD_JOBS} CPU cores..." && \
        cargo build --release --jobs ${BUILD_JOBS} --target ${TARGET}; \
    fi && \
    echo "Build completed successfully!"

# Show sccache statistics
RUN sccache --show-stats

# -----------------------------------------------------------------------------
# Stage 3: Runtime Environment (Minimal Arch Linux)
# -----------------------------------------------------------------------------
FROM archlinux:base-devel AS runtime

# Install minimal runtime dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        glibc \
        && \
    pacman -Scc --noconfirm

# Create app user
RUN useradd -r -s /bin/false lyvoxa

# Create app directory
WORKDIR /app

# Copy built binaries from builder stage
COPY --from=app-builder /tmp/target/x86_64-unknown-linux-gnu/release/lyvoxa /usr/local/bin/lyvoxa
COPY --from=app-builder /tmp/target/x86_64-unknown-linux-gnu/release/lyvoxa-simple /usr/local/bin/lyvoxa-simple

# Set proper permissions
RUN chmod +x /usr/local/bin/lyvoxa /usr/local/bin/lyvoxa-simple

# Create symlinks for easier access
RUN ln -s /usr/local/bin/lyvoxa /usr/local/bin/monitor && \
    ln -s /usr/local/bin/lyvoxa-simple /usr/local/bin/monitor-simple

# Switch to app user
USER lyvoxa

# Set default command
CMD ["lyvoxa"]

# Add labels for metadata
LABEL maintainer="rezky_nightky"
LABEL version="stellar-1.5"
LABEL description="Lyvoxa - High-performance system monitor for Linux"
LABEL org.opencontainers.image.source="https://github.com/oxyzenQ/lyvoxa"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# -----------------------------------------------------------------------------
# Stage 4: Development Environment (Optional)
# -----------------------------------------------------------------------------
FROM builder AS dev

# Install additional development tools
RUN cargo install cargo-watch cargo-audit cargo-outdated

# Set working directory
WORKDIR /workspace

# Default command for development
CMD ["bash"]

# =============================================================================
# BUILD INSTRUCTIONS
# =============================================================================
# 
# Build production image:
#   docker build --target runtime --cpus=3 -t lyvoxa:stellar-1.5 .
# 
# Build development image:
#   docker build --target dev --cpus=3 -t lyvoxa:dev .
# 
# Run with volume mounts for caching:
#   docker run --rm --cpus=3 \
#     -v lyvoxa-target:/tmp/target \
#     -v lyvoxa-sccache:/tmp/sccache \
#     lyvoxa:stellar-1.5
# 
# Development with source mount:
#   docker run --rm -it --cpus=3 \
#     -v $(pwd):/workspace \
#     -v lyvoxa-target:/tmp/target \
#     -v lyvoxa-sccache:/tmp/sccache \
#     lyvoxa:dev
# 
# =============================================================================

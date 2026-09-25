# syntax=docker/dockerfile:1
# ---- Music Room mobile client (Flutter -> web build) ----
# We only target WEB, so we install just the Flutter SDK (no Android SDK).
# SDK is cloned from git (stable/beta branch or exact tag) so the correct
# Dart SDK for the host arch (amd64/arm64) is downloaded on first run.
# NOTE: releases_linux.json only ships x64 tarballs -> breaks on arm64
# (Apple Silicon) with `rosetta error ... ld-linux-x86-64.so.2` + exit 133.

# ---------- Stage 1: build Flutter web ----------
FROM debian:bookworm-slim AS builder

# Backend base URL baked into the web bundle. Override with:
#   docker build --build-arg BACKEND_URL=http://myhost:3001 -f mobile/Dockerfile .
ARG BACKEND_URL=http://localhost:8081
# Pin a channel (stable/beta) and optionally an exact version for reproducibility.
ARG FLUTTER_CHANNEL=stable
ARG FLUTTER_VERSION=

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Robust apt: retry on transient debian mirror "Hash Sum mismatch" (seen on
# slow/proxied Docker Desktop networks). Cleans stale lists, disables HTTP
# pipelining (avoids corrupted partial downloads), retries update+install.
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    echo 'Acquire::http::Pipeline-Depth "0";' > /etc/apt/apt.conf.d/99-nopipeline; \
    echo 'Acquire::http::No-Cache "true";' >> /etc/apt/apt.conf.d/99-nopipeline; \
    echo 'Acquire::BrokenProxy "true";' >> /etc/apt/apt.conf.d/99-nopipeline; \
    rm -rf /var/lib/apt/lists/*; apt-get clean; \
    for i in 1 2 3 4 5; do \
      apt-get update -o Acquire::Retries=5 && break || { echo "apt-get update attempt $i failed, retrying..."; sleep 8; rm -rf /var/lib/apt/lists/*; apt-get clean; }; \
      if [ "$i" = 5 ]; then echo "apt-get update failed after 5 attempts" >&2; exit 100; fi; \
    done; \
    apt-get install -y --no-install-recommends ca-certificates curl git jq unzip xz-utils \
      || { echo "install failed, refreshing lists once and retrying with --fix-missing..."; rm -rf /var/lib/apt/lists/*; apt-get clean; apt-get update -o Acquire::Retries=5; apt-get install -y --no-install-recommends --fix-missing ca-certificates curl git jq unzip xz-utils; }; \
    rm -rf /var/lib/apt/lists/*

# Clone the Flutter SDK from git so the correct Dart SDK for the host arch
# (amd64/arm64) is fetched on first run. An exact tag (FLUTTER_VERSION like
# 3.24.0) wins over the channel branch (FLUTTER_CHANNEL: stable/beta).
# Runs as non-root `flutter` user: avoids "running as root" warning and
# matches Flutter's recommended usage.
RUN set -eux; \
    if [ -n "$FLUTTER_VERSION" ]; then BRANCH="$FLUTTER_VERSION"; else BRANCH="$FLUTTER_CHANNEL"; fi; \
    echo "Cloning Flutter branch/tag: $BRANCH"; \
    rm -rf /opt/flutter; \
    git clone --depth 1 --branch "$BRANCH" https://github.com/flutter/flutter.git /opt/flutter; \
    useradd -m -s /bin/bash flutter || true; \
    mkdir -p /app; chown -R flutter:flutter /opt/flutter /app; \
    git config --global --add safe.directory /opt/flutter; \
    su flutter -c "git config --global --add safe.directory /opt/flutter"

WORKDIR /app
RUN chown flutter:flutter /app
USER flutter

# Generate the missing web/ scaffold (repo ships lib/ + pubspec.yaml only)
# and fetch dependencies. Copied first for better layer caching.
COPY --chown=flutter:flutter mobile/pubspec.yaml ./
RUN flutter config --no-analytics \
    && flutter create --platforms=web --project-name musicroom . \
    && flutter precache --web \
    && flutter pub get

# Copy sources and build a release web bundle with the injected backend URL.
COPY --chown=flutter:flutter mobile/lib ./lib
RUN flutter build web --release --dart-define=BACKEND_URL="${BACKEND_URL}"

USER root

# ---------- Stage 2: serve static bundle ----------
FROM nginx:1.27-alpine AS runtime
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY mobile/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
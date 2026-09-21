# syntax=docker/dockerfile:1
# ---- Music Room mobile client (Flutter -> web build) ----
# We only target WEB, so we install just the Flutter SDK (no Android SDK).
# The SDK is resolved from Flutter's official release manifest, so the
# downloaded archive always exists (avoids fragile hard-coded version pins).

# ---------- Stage 1: build Flutter web ----------
FROM debian:bookworm-slim AS builder

# Backend base URL baked into the web bundle. Override with:
#   docker build --build-arg BACKEND_URL=http://myhost:3000 -f mobile/Dockerfile .
ARG BACKEND_URL=http://localhost:8080
# Pin a channel (stable/beta) and optionally an exact version for reproducibility.
ARG FLUTTER_CHANNEL=stable
ARG FLUTTER_VERSION=

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git jq unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download + unpack the Flutter SDK (web artifacts only are fetched later).
RUN set -eux; \
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json -o /tmp/releases.json; \
    base=$(jq -r .base_url /tmp/releases.json); \
    if [ -n "$FLUTTER_VERSION" ]; then \
      archive=$(jq -r --arg v "$FLUTTER_VERSION" --arg c "$FLUTTER_CHANNEL" \
        '.releases[] | select(.version==$v and .channel==$c) | .archive' /tmp/releases.json | head -n1); \
    else \
      hash=$(jq -r --arg c "$FLUTTER_CHANNEL" '.current_release[$c]' /tmp/releases.json); \
      archive=$(jq -r --arg h "$hash" '.releases[] | select(.hash==$h) | .archive' /tmp/releases.json); \
    fi; \
    test -n "$archive" && test "$archive" != "null"; \
    mkdir -p /opt; \
    curl -fsSL "$base/$archive" -o /tmp/flutter.tar.xz; \
    tar -xJf /tmp/flutter.tar.xz -C /opt; \
    rm -f /tmp/flutter.tar.xz /tmp/releases.json; \
    git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"

WORKDIR /app

# Generate the missing web/ scaffold (repo ships lib/ + pubspec.yaml only)
# and fetch dependencies. Copied first for better layer caching.
COPY mobile/pubspec.yaml ./
RUN flutter config --no-analytics \
    && flutter create --platforms=web --project-name musicroom . \
    && flutter precache --web \
    && flutter pub get

# Copy sources and build a release web bundle with the injected backend URL.
COPY mobile/lib ./lib
RUN flutter build web --release --dart-define=BACKEND_URL="${BACKEND_URL}"

# ---------- Stage 2: serve static bundle ----------
FROM nginx:1.27-alpine AS runtime
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY mobile/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
#!/usr/bin/env bash
# scripts/00-env.sh
# Source this before every demo: `source scripts/00-env.sh`
# Works on: macOS (Docker or Podman) · Linux · Windows WSL2

set -euo pipefail

echo "🔧 Configuring environment for Floci..."

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_PAGER=""  # disable the pager so output prints directly to terminal

echo "✅ AWS_ENDPOINT_URL   = $AWS_ENDPOINT_URL"
echo "✅ AWS_DEFAULT_REGION = $AWS_DEFAULT_REGION"

OS="$(uname -s)"

# ── macOS: check container runtime ──────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  if command -v podman &>/dev/null; then
    RUNTIME="Podman"
    if ! podman machine inspect &>/dev/null; then
      echo "⚠️  Podman machine not running. Starting it..."
      podman machine start
    fi
  elif command -v docker &>/dev/null; then
    RUNTIME="Docker"
    if ! docker info &>/dev/null; then
      echo "❌ Docker Desktop is not running. Please open Docker Desktop and retry."
      return 1 2>/dev/null || exit 1
    fi
  else
    echo "❌ No container runtime found. Install Docker Desktop or Podman."
    return 1 2>/dev/null || exit 1
  fi

# ── Linux / Windows WSL2 ────────────────────────────────────────────────────
elif [[ "$OS" == "Linux" ]]; then
  if command -v podman &>/dev/null; then
    RUNTIME="Podman"
    PODMAN_SOCK="/run/user/$(id -u)/podman/podman.sock"
    if [[ -S "$PODMAN_SOCK" ]]; then
      export DOCKER_HOST="unix://$PODMAN_SOCK"
      echo "✅ DOCKER_HOST set to Podman socket (for Testcontainers)"
    fi
  elif command -v docker &>/dev/null; then
    RUNTIME="Docker"
  else
    echo "❌ No container runtime found. Install Docker or Podman."
    return 1 2>/dev/null || exit 1
  fi
fi

echo "✅ Runtime: $RUNTIME"

# ── Verify Floci is reachable ───────────────────────────────────────────────
if curl -sf "$AWS_ENDPOINT_URL/_floci/health" > /dev/null 2>&1; then
  echo "✅ Floci is running at $AWS_ENDPOINT_URL"
else
  echo "❌ Floci is NOT reachable at $AWS_ENDPOINT_URL"
  echo "   Start it with one of:"
  echo "     docker run -d --name floci -p 4566:4566 floci/floci:latest"
  echo "     podman run -d --name floci -p 4566:4566 floci/floci:latest"
  echo "     docker compose up -d"
  echo "     podman compose up -d"
  return 1 2>/dev/null || exit 1
fi

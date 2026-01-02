#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VUE_APP_DIR="$ROOT_DIR/vue"
if [ ! -d "$VUE_APP_DIR" ]; then
  echo "Vue workspace not found at $VUE_APP_DIR" >&2
  exit 1
fi

PROJECT_SLUG="$(basename "$ROOT_DIR" | tr '[:upper:]' '[:lower:]')"
DEFAULT_TARGET_DIR="/var/www/${PROJECT_SLUG}-vue"
TARGET_DIR="${1:-$DEFAULT_TARGET_DIR}"

PACKAGE_MANAGER="${PACKAGE_MANAGER:-}"
if [ -z "$PACKAGE_MANAGER" ]; then
  if [ -f "$VUE_APP_DIR/pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER=pnpm
  elif [ -f "$VUE_APP_DIR/yarn.lock" ]; then
    PACKAGE_MANAGER=yarn
  else
    PACKAGE_MANAGER=npm
  fi
fi

case "$PACKAGE_MANAGER" in
  pnpm)
    INSTALL_CMD=("pnpm" "install")
    BUILD_CMD=("pnpm" "run" "build")
    ;;
  yarn)
    INSTALL_CMD=("yarn" "install")
    BUILD_CMD=("yarn" "build")
    ;;
  npm)
    if [ -f "$VUE_APP_DIR/package-lock.json" ]; then
      INSTALL_CMD=("npm" "ci")
    else
      INSTALL_CMD=("npm" "install")
    fi
    BUILD_CMD=("npm" "run" "build")
    ;;
  *)
    echo "Unsupported PACKAGE_MANAGER: $PACKAGE_MANAGER" >&2
    exit 1
    ;;
esac

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required to sync the build output." >&2
  exit 1
fi

echo "Building Vue app using $PACKAGE_MANAGER from $VUE_APP_DIR"
cd "$VUE_APP_DIR"
"${INSTALL_CMD[@]}"
"${BUILD_CMD[@]}"

BUILD_OUTPUT_DIR="$VUE_APP_DIR/dist"
if [ ! -d "$BUILD_OUTPUT_DIR" ]; then
  echo "Expected build output at $BUILD_OUTPUT_DIR but directory is missing." >&2
  exit 1
fi

echo "Syncing build output to $TARGET_DIR"
mkdir -p "$TARGET_DIR"
rsync -a --delete "$BUILD_OUTPUT_DIR"/ "$TARGET_DIR"/

echo "Vue deployment complete. Served from $TARGET_DIR."

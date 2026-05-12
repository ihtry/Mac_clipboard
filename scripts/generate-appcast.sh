#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${1:-$ROOT_DIR/dist}"
GENERATE_APPCAST="${SPARKLE_GENERATE_APPCAST:-}"

if [[ -z "$GENERATE_APPCAST" ]]; then
  GENERATE_APPCAST="$(find "$ROOT_DIR/build" "$HOME/Library/Developer/Xcode/DerivedData" -path '*/Sparkle/bin/generate_appcast' -type f 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$GENERATE_APPCAST" || ! -x "$GENERATE_APPCAST" ]]; then
  echo "Sparkle generate_appcast not found. Set SPARKLE_GENERATE_APPCAST=/path/to/generate_appcast." >&2
  exit 1
fi

if [[ ! -d "$DIST_DIR" ]]; then
  echo "Distribution directory not found: $DIST_DIR" >&2
  exit 1
fi

"$GENERATE_APPCAST" "$DIST_DIR"

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/notarize-dmg.sh dist/T-clipboard.dmg" >&2
  exit 1
fi

DMG_PATH="$1"
PROFILE="${NOTARYTOOL_PROFILE:-}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found: $DMG_PATH" >&2
  exit 1
fi

if [[ -z "$PROFILE" ]]; then
  echo "Set NOTARYTOOL_PROFILE to a keychain profile created with xcrun notarytool store-credentials." >&2
  exit 1
fi

xcrun notarytool submit "$DMG_PATH" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

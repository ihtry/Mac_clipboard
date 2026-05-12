#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/clipboard.xcodeproj"
SCHEME="clipboard"
CONFIGURATION="Release"
APP_NAME="T clipboard"
APP_BUNDLE_NAME="$APP_NAME.app"
DMG_NAME="T-clipboard.dmg"
DIST_DIR="$ROOT_DIR/dist"
DMG_ROOT="$DIST_DIR/dmg-root"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
DMG_PATH="$DIST_DIR/$DMG_NAME"
APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_BUNDLE_NAME"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
ENTITLEMENTS="$ROOT_DIR/clipboard/clipboard.entitlements"

set_plist_value() {
  local plist_path="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist_path" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :$key $type $value" "$plist_path"
}

first_codesign_identity() {
  security find-identity -v -p codesigning \
    | sed -n 's/^ *[0-9]*) [A-F0-9]* "\(.*\)"$/\1/p' \
    | head -n 1
}

detach_existing_image() {
  local image_path="$1"
  local info
  local current_image=""
  local device

  info="$(hdiutil info)"
  while IFS= read -r line; do
    case "$line" in
      image-path*)
        current_image="${line#*: }"
        ;;
      /dev/*)
        if [[ "$current_image" == "$image_path" ]]; then
          device="${line%%[[:space:]]*}"
          hdiutil detach "$device" >/dev/null 2>&1 || true
        fi
        ;;
    esac
  done <<< "$info"
}

verify_dmg() {
  local image_path="$1"

  for attempt in 1 2 3; do
    if hdiutil verify "$image_path"; then
      return 0
    fi

    detach_existing_image "$image_path"
    sleep "$attempt"
  done

  hdiutil verify "$image_path"
}

detach_existing_image "$DMG_PATH"
rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"

xcodebuild_args=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA"
)

if [[ -n "${SPARKLE_FEED_URL:-}" ]]; then
  xcodebuild_args+=("SPARKLE_FEED_URL=$SPARKLE_FEED_URL")
fi

if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  xcodebuild_args+=("SPARKLE_PUBLIC_ED_KEY=$SPARKLE_PUBLIC_ED_KEY")
fi

xcodebuild "${xcodebuild_args[@]}" build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release app not found: $APP_PATH" >&2
  exit 1
fi

APP_PLIST="$APP_PATH/Contents/Info.plist"
if [[ -n "${SPARKLE_FEED_URL:-}" ]]; then
  set_plist_value "$APP_PLIST" "SUFeedURL" "string" "$SPARKLE_FEED_URL"
fi

if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  set_plist_value "$APP_PLIST" "SUPublicEDKey" "string" "$SPARKLE_PUBLIC_ED_KEY"
fi

set_plist_value "$APP_PLIST" "SUEnableAutomaticChecks" "bool" "true"
set_plist_value "$APP_PLIST" "SUEnableInstallerLauncherService" "bool" "true"

if ! codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
  if [[ -z "$SIGN_IDENTITY" ]]; then
    SIGN_IDENTITY="$(first_codesign_identity)"
  fi

  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "No codesigning identity found. Set SIGN_IDENTITY to re-sign the app." >&2
    exit 1
  fi

  codesign \
    --force \
    --options runtime \
    --timestamp=none \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$APP_PATH"
fi

cp -R "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

detach_existing_image "$DMG_PATH"
verify_dmg "$DMG_PATH"

echo "$DMG_PATH"

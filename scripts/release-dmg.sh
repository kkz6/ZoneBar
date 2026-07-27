#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/ZoneBar.xcodeproj"
SCHEME="${SCHEME:-ZoneBar}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/release}"
ARCHIVE_PATH="$BUILD_DIR/ZoneBar.xcarchive"
STAGING_DIR="$BUILD_DIR/dmg"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PATH="$BACKGROUND_DIR/background.png"
BACKGROUND_SCRIPT="$ROOT_DIR/scripts/create-dmg-background.swift"
APP_ICON="$ROOT_DIR/ZoneBar/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"
TEAM_ID="${TEAM_ID:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_KEY="${NOTARY_KEY:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${NOTARY_ISSUER_ID:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

VERSION="$(
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration Release \
        -showBuildSettings 2>/dev/null |
        awk '/MARKETING_VERSION/ { print $3; exit }'
)"
DMG_PATH="$BUILD_DIR/ZoneBar-${VERSION}.dmg"
RW_DMG_PATH="$BUILD_DIR/ZoneBar-${VERSION}-rw.dmg"

if [[ -z "$BUILD_NUMBER" ]]; then
    BUILD_NUMBER="$(
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration Release \
            -showBuildSettings 2>/dev/null |
            awk '/CURRENT_PROJECT_VERSION/ { print $3; exit }'
    )"
fi

if [[ -z "$VERSION" || -z "$TEAM_ID" ]]; then
    echo "Set TEAM_ID to the Apple Developer team used for this release."
    exit 1
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY="$(
        security find-identity -v -p codesigning |
            sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' |
            head -1
    )"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
    echo "No Developer ID Application certificate was found."
    exit 1
fi

if [[ "$SKIP_NOTARIZATION" != "1" &&
      -z "$NOTARY_PROFILE" &&
      ( -z "$NOTARY_KEY" || -z "$NOTARY_KEY_ID" || -z "$NOTARY_ISSUER_ID" ) ]]; then
    echo "Configure NOTARY_PROFILE or NOTARY_KEY, NOTARY_KEY_ID, and NOTARY_ISSUER_ID."
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$STAGING_DIR" "$BACKGROUND_DIR"

echo "Archiving ZoneBar ${VERSION}…"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    clean archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/ZoneBar.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Archived app was not found at $APP_PATH."
    exit 1
fi

# A direct archive copy does not perform Xcode's export step, which normally
# re-signs Sparkle's nested helpers with our Developer ID identity. Apple
# rejects the DMG if those helpers retain Sparkle's upstream signatures.
SPARKLE_FRAMEWORK="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
    SPARKLE_VERSION_DIR="$SPARKLE_FRAMEWORK/Versions/Current"

    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        "$SPARKLE_VERSION_DIR/XPCServices/Installer.xpc"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        --preserve-metadata=entitlements \
        "$SPARKLE_VERSION_DIR/XPCServices/Downloader.xpc"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        "$SPARKLE_VERSION_DIR/Autoupdate"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        "$SPARKLE_VERSION_DIR/Updater.app"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        "$SPARKLE_FRAMEWORK"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime \
        --preserve-metadata=entitlements,requirements,flags \
        "$APP_PATH"
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto "$APP_PATH" "$STAGING_DIR/ZoneBar.app"
ln -s /Applications "$STAGING_DIR/Applications"
xcrun swift "$BACKGROUND_SCRIPT" "$APP_ICON" "$BACKGROUND_PATH"

echo "Creating disk image…"
hdiutil create \
    -volname "ZoneBar" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDRW \
    "$RW_DMG_PATH"

DEVICE=""

cleanup_mount() {
    if [[ -n "$DEVICE" ]]; then
        hdiutil detach "$DEVICE" -force >/dev/null 2>&1 || true
    fi
}
trap cleanup_mount EXIT

DEVICE="$(
    hdiutil attach \
        -readwrite \
        -noverify \
        -noautoopen \
        "$RW_DMG_PATH" |
        awk '/Apple_APFS|Apple_HFS/ { print $1; exit }'
)"

if [[ -z "$DEVICE" ]]; then
    echo "Unable to mount the writable disk image."
    exit 1
fi

osascript <<APPLESCRIPT
tell application "Finder"
    delay 2
    tell disk "ZoneBar"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set bounds of container window to {120, 120, 800, 550}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 112
        set text size of theViewOptions to 13
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "ZoneBar.app" to {190, 218}
        set position of item "Applications" to {490, 218}
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEVICE"
DEVICE=""
hdiutil convert \
    "$RW_DMG_PATH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"
rm -f "$RW_DMG_PATH"

codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH"

if [[ "$SKIP_NOTARIZATION" == "1" ]]; then
    echo "Skipping notarization. Do not publish this development artifact."
else
    echo "Submitting disk image to Apple for notarization…"
    if [[ -n "$NOTARY_PROFILE" ]]; then
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$NOTARY_PROFILE" \
            --wait
    else
        xcrun notarytool submit "$DMG_PATH" \
            --key "$NOTARY_KEY" \
            --key-id "$NOTARY_KEY_ID" \
            --issuer "$NOTARY_ISSUER_ID" \
            --wait
    fi

    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"
fi

(
    cd "$BUILD_DIR"
    dmg_name="$(basename "$DMG_PATH")"
    shasum -a 256 "$dmg_name" > "$dmg_name.sha256"
)
echo "Release ready: $DMG_PATH"

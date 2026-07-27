#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/ZoneBar.xcodeproj"
SCHEME="${SCHEME:-ZoneBar}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/release}"
ARCHIVE_PATH="$BUILD_DIR/ZoneBar.xcarchive"
STAGING_DIR="$BUILD_DIR/dmg"
TEAM_ID="${TEAM_ID:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_KEY="${NOTARY_KEY:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${NOTARY_ISSUER_ID:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"

VERSION="$(
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration Release \
        -showBuildSettings 2>/dev/null |
        awk '/MARKETING_VERSION/ { print $3; exit }'
)"
DMG_PATH="$BUILD_DIR/ZoneBar-${VERSION}.dmg"

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
mkdir -p "$BUILD_DIR" "$STAGING_DIR"

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
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    clean archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/ZoneBar.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Archived app was not found at $APP_PATH."
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto "$APP_PATH" "$STAGING_DIR/ZoneBar.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating disk image…"
hdiutil create \
    -volname "ZoneBar" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

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

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "Release ready: $DMG_PATH"

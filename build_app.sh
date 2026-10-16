#!/bin/zsh
# Builds "DMGEKI.app" (Apple Silicon) with Sparkle auto-update, ad-hoc signed.
set -euo pipefail
cd "$(dirname "$0")"

source ./release.conf

APP_NAME="DMGEKI"
APP="$APP_NAME.app"

SPARKLE_VERSION="2.10.0"
SPARKLE_SHA256="c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c"
SPARKLE_DIR=".vendor/Sparkle-$SPARKLE_VERSION"

# Sparkle (auto-update framework), downloaded once and checksum-verified (same as STEMEKI, CHORDEKI, EXEKI).
if [[ ! -d "$SPARKLE_DIR/Sparkle.framework" ]]; then
    echo "→ Sparkle $SPARKLE_VERSION letöltése"
    mkdir -p "$SPARKLE_DIR"
    ARCHIVE="$SPARKLE_DIR.tar.xz"
    curl -sSL -o "$ARCHIVE" "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
    echo "$SPARKLE_SHA256  $ARCHIVE" | shasum -a 256 -c --status || { echo "✗ Sparkle ellenőrzőösszeg hibás"; rm -rf "$SPARKLE_DIR" "$ARCHIVE"; exit 1; }
    tar -xf "$ARCHIVE" -C "$SPARKLE_DIR"
    rm "$ARCHIVE"
fi

echo "→ Fordítás (SwiftPM, release)"
# SwiftPM build (a plain swiftc build of the same sources crashes SwiftUI's split view layout at launch).
SPARKLE_ABS="$PWD/$SPARKLE_DIR"
swift build -c release \
    -Xswiftc -F -Xswiftc "$SPARKLE_ABS" \
    -Xlinker -F -Xlinker "$SPARKLE_ABS" -Xlinker -framework -Xlinker Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks
BIN=".build/release/DMGCanvasApp"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
ditto "$SPARKLE_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
PLIST="$APP/Contents/Info.plist"
cp Info.plist "$PLIST"
/usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $(cat sparkle-public-key.txt)" "$PLIST"
if [[ -n "$GITHUB_REPO" ]]; then
    /usr/libexec/PlistBuddy -c "Add :SUFeedURL string https://github.com/$GITHUB_REPO/releases/latest/download/appcast.xml" "$PLIST"
else
    echo "  (release.conf: GITHUB_REPO üres → automatikus frissítés kikapcsolva)"
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "→ Aláírás (ad-hoc)"
codesign --force --deep --sign - "$APP"

# Refresh Finder / Dock icon cache so a changed AppIcon shows up immediately
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true

echo "✓ Kész: $APP"

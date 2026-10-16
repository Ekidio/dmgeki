#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DMGEKI"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Building Swift binary (Release)..."
swift build -c release

BIN_PATH=".build/release/DMGCanvasApp"
if [ ! -f "${BIN_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BIN_PATH}"
    exit 1
fi

echo "📦 Packaging ${APP_NAME}.app bundle..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy AppIcon.icns
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
elif [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Generate Info.plist
cat << EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.ekidio.dmgeki</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>DMGEKI</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>DMGEKI requires permission to control Finder via AppleScript to set window layouts, icon positions, and background styling for created disk images.</string>
</dict>
</plist>
EOF

echo "🔏 Ad-hoc code signing app bundle..."
codesign --force --deep --sign - "${BUNDLE_DIR}"

# Refresh Finder / Dock icon cache so a changed AppIcon shows up immediately
touch "${BUNDLE_DIR}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${BUNDLE_DIR}" || true

echo "✅ App bundle created successfully at: ${BUNDLE_DIR}"
echo "💡 You can launch it with: open ${BUNDLE_DIR}"

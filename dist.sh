#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="CCQuick"
VERSION="1.0.0"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"

# Step 1: Build
echo "=== Building $APP_NAME ==="
bash build.sh

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Build failed"
    exit 1
fi

# Step 2: Stage
echo ""
echo "=== Creating DMG ==="
rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Step 3: Create DMG directly (simple, no Finder scripting)
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    -fs HFS+ \
    "$DMG_PATH" \
    > /dev/null 2>&1

rm -rf "$DMG_DIR"

DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
echo ""
echo "=== Distribution Ready ==="
echo "  DMG: $DMG_PATH ($DMG_SIZE)"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME to Applications"
echo "  3. Right-click > Open (first launch only)"

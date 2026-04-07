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
TEMP_DMG="$BUILD_DIR/temp_$DMG_NAME.dmg"

# Step 1: Build
echo "=== Building $APP_NAME ==="
bash build.sh

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Build failed"
    exit 1
fi

# Step 2: Create background image
echo ""
echo "=== Creating DMG ==="
BG_IMG="$BUILD_DIR/dmg_bg.png"
python3 << 'BGEOF'
import zlib, struct

W, H = 1080, 660  # @2x for 540x330 window

def write_png(w, h, pixels, path):
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    raw = b''
    for y in range(h):
        raw += b'\x00'
        for x in range(w):
            raw += bytes(pixels[y * w + x])
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw, 9)))
        f.write(chunk(b'IEND', b''))

px = []
for y in range(H):
    for x in range(W):
        ny = y / H
        # Dark gradient
        r = int(30 + ny * 10)
        g = int(30 + ny * 10)
        b = int(33 + ny * 10)

        # Center arrow pointing right
        cx, cy = W // 2, H // 2
        dx, dy = x - cx, y - cy
        ar, ag, ab = 140, 140, 150  # arrow color
        # Arrow body
        if -80 <= dx <= 40 and -6 <= dy <= 6:
            r, g, b = ar, ag, ab
        # Arrow head (triangle)
        if 20 <= dx <= 90:
            hh = int((90 - dx) * 0.7)
            if -hh <= dy <= hh:
                r, g, b = ar, ag, ab

        px.append((r, g, b, 255))

write_png(W, H, px, "build/dmg_bg.png")
BGEOF

# Stage
rm -rf "$DMG_DIR" "$DMG_PATH" "$TEMP_DMG"
mkdir -p "$DMG_DIR/.background"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
cp "$BG_IMG" "$DMG_DIR/.background/bg.png"
rm -f "$BG_IMG"

# Step 3: Create writable DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$TEMP_DMG" \
    > /dev/null 2>&1

# Step 4: Mount and configure
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen 2>/dev/null | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

echo "  Configuring layout..."

# Auto-open when mounted
bless --folder "$MOUNT_DIR" --openfolder "$MOUNT_DIR" 2>/dev/null || true

# Finder window layout
osascript -e "
tell application \"Finder\"
    tell disk \"$APP_NAME\"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {300, 200, 840, 530}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        set background picture of theViewOptions to file \".background:bg.png\"
        set position of item \"$APP_NAME.app\" of container window to {135, 155}
        set position of item \"Applications\" of container window to {405, 155}
        close
    end tell
end tell
" 2>/dev/null

sleep 2
sync
hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1

# Step 5: Compress (UDBZ preserves bless metadata)
hdiutil convert "$TEMP_DMG" -format UDBZ -o "$DMG_PATH" > /dev/null 2>&1
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

# Done
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
echo ""
echo "=== Distribution Ready ==="
echo "  DMG: $DMG_PATH ($DMG_SIZE)"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME to Applications"
echo "  3. Run: xattr -cr /Applications/$APP_NAME.app"
echo "  4. Open $APP_NAME"

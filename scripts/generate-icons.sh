#!/bin/bash

# Generate app icon set from ackbar.png

set -e

if [ ! -f "img/ackbar.png" ]; then
    echo "Error: img/ackbar.png not found"
    exit 1
fi

echo "Creating icon set from img/ackbar.png..."

# Create iconset directory
mkdir -p AppIcon.iconset

# Generate all required sizes
sips -z 16 16     img/ackbar.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     img/ackbar.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     img/ackbar.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     img/ackbar.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   img/ackbar.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   img/ackbar.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   img/ackbar.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   img/ackbar.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   img/ackbar.png --out AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 img/ackbar.png --out AppIcon.iconset/icon_512x512@2x.png

# Generate icns file
iconutil -c icns AppIcon.iconset -o AppIcon.icns

# Clean up
rm -rf AppIcon.iconset

echo "✓ AppIcon.icns created successfully"
#!/bin/bash

# Script to create a demo video/GIF for Ackbar
# Requires: ffmpeg

set -e

OUTPUT_DIR="demo"
OUTPUT_FILE="ackbar-demo.mp4"
GIF_FILE="ackbar-demo.gif"

echo "📹 Creating Ackbar demo video..."

# Check dependencies
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ ffmpeg is required but not installed."
    echo "Install with: brew install ffmpeg"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to capture menu bar area
capture_menubar() {
    local output=$1
    local duration=$2
    
    echo "Recording menu bar for $duration seconds..."
    
    # Get screen dimensions
    SCREEN_WIDTH=$(system_profiler SPDisplaysDataType | grep Resolution | head -1 | grep -o '[0-9]\+' | head -1)
    SCREEN_HEIGHT=60  # Just the menu bar area
    
    # Record menu bar area using ffmpeg
    ffmpeg -f avfoundation -capture_cursor 1 -i "1:none" \
           -vf "crop=$SCREEN_WIDTH:$SCREEN_HEIGHT:0:0" \
           -t "$duration" -pix_fmt yuv420p -y "$output" 2>/dev/null
}

echo "📋 Demo scenario:"
echo "1. Show menu bar with many icons"
echo "2. Launch Ackbar app"
echo "3. Drag icons to the left of separator"
echo "4. Click chevron to hide icons"
echo "5. Show auto-hide in action"
echo "6. Use keyboard shortcut ⌘⌃M"
echo "7. Right-click menu options"
echo "8. Emergency reset with ⌘⌃⌥M"
echo ""
echo "⚠️  Please arrange your menu bar with many icons before continuing"
echo "Press Enter when ready..."
read

# Step 1: Record initial state
echo "Step 1: Recording menu bar with icons visible..."
capture_menubar "$OUTPUT_DIR/01_initial.mp4" 3

# Step 2: Show Ackbar launch
echo "Step 2: Please launch Ackbar.app from Applications"
echo "Press Enter after launching..."
read
capture_menubar "$OUTPUT_DIR/02_launched.mp4" 3

# Step 3: Show dragging icons
echo "Step 3: Please drag some icons to the LEFT of the separator"
echo "Press Enter after arranging..."
read
capture_menubar "$OUTPUT_DIR/03_arranged.mp4" 3

# Step 4: Show hiding icons
echo "Step 4: Please click the chevron to hide icons"
echo "Press Enter after hiding..."
read
capture_menubar "$OUTPUT_DIR/04_hidden.mp4" 3

# Step 5: Show expanding
echo "Step 5: Please click the chevron again to show icons"
echo "Press Enter after showing..."
read
capture_menubar "$OUTPUT_DIR/05_shown.mp4" 3

# Step 6: Show keyboard shortcut
echo "Step 6: Please press ⌘⌃M to toggle (do it twice)"
echo "Press Enter when done..."
read
capture_menubar "$OUTPUT_DIR/06_keyboard.mp4" 4

# Step 7: Show right-click menu
echo "Step 7: Please right-click the chevron to show menu"
echo "Press Enter when done..."
read
capture_menubar "$OUTPUT_DIR/07_menu.mp4" 3

# Combine all clips
echo "Combining clips..."
cat > "$OUTPUT_DIR/concat.txt" <<EOF
file '01_initial.mp4'
file '02_launched.mp4'
file '03_arranged.mp4'
file '04_hidden.mp4'
file '05_shown.mp4'
file '06_keyboard.mp4'
file '07_menu.mp4'
EOF

ffmpeg -f concat -safe 0 -i "$OUTPUT_DIR/concat.txt" \
       -c:v libx264 -preset slow -crf 22 \
       -y "$OUTPUT_FILE" 2>/dev/null

echo "✅ Video created: $OUTPUT_FILE"
echo "   Size: $(du -h "$OUTPUT_FILE" | cut -f1)"

# Create GIF version
echo "Creating GIF version..."
ffmpeg -i "$OUTPUT_FILE" \
       -vf "fps=10,scale=-1:60:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
       -loop 0 -y "$GIF_FILE" 2>/dev/null

# Optimize GIF if gifsicle is available
if command -v gifsicle &> /dev/null; then
    echo "Optimizing GIF..."
    gifsicle -O3 --lossy=30 -o "$GIF_FILE" "$GIF_FILE"
fi

echo "✅ GIF created: $GIF_FILE"
echo "   Size: $(du -h "$GIF_FILE" | cut -f1)"

# Create before/after comparison screenshot
echo ""
echo "Creating before/after comparison..."
echo "Please arrange menu bar with all icons visible"
echo "Press Enter when ready..."
read

# Take before screenshot
screencapture -x -R0,0,$SCREEN_WIDTH,60 "$OUTPUT_DIR/before.png"

echo "Now hide the icons with Ackbar"
echo "Press Enter when hidden..."
read

# Take after screenshot
screencapture -x -R0,0,$SCREEN_WIDTH,60 "$OUTPUT_DIR/after.png"

# Create side-by-side comparison using ImageMagick if available
if command -v convert &> /dev/null; then
    convert "$OUTPUT_DIR/before.png" "$OUTPUT_DIR/after.png" +append \
            -border 2x2 -bordercolor "#333" \
            "comparison.png"
    echo "✅ Comparison image created: comparison.png"
else
    echo "ℹ️  Install ImageMagick for comparison image: brew install imagemagick"
    cp "$OUTPUT_DIR/before.png" "before.png"
    cp "$OUTPUT_DIR/after.png" "after.png"
    echo "✅ Screenshots saved: before.png and after.png"
fi

# Cleanup
rm -rf "$OUTPUT_DIR"

echo ""
echo "🎬 Demo creation complete!"
echo "Files created:"
echo "  - $OUTPUT_FILE (full demo video)"
echo "  - $GIF_FILE (animated GIF)"
echo "  - comparison.png or before/after.png (screenshots)"
echo ""
echo "Upload these to your repository for the README!"
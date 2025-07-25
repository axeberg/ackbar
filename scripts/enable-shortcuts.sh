#!/bin/bash

# Enable keyboard shortcuts for Ackbar

echo "🔧 Ackbar Keyboard Shortcuts Setup"
echo "=================================="
echo ""
echo "Ackbar needs accessibility permissions to enable global keyboard shortcuts:"
echo "  • ⌘⌃M - Toggle hide/show icons"
echo "  • ⌘⌃⌥M - Emergency reset"
echo ""

# Check if running as app or binary
if [[ -d "/Applications/Ackbar.app" ]]; then
    APP_PATH="/Applications/Ackbar.app"
    echo "✓ Found Ackbar.app at $APP_PATH"
elif command -v ackbar &> /dev/null; then
    APP_PATH=$(which ackbar)
    echo "✓ Found ackbar binary at $APP_PATH"
else
    echo "❌ Ackbar not found. Please install it first."
    exit 1
fi

# Check if Ackbar is actually running (not just grep)
if pgrep -x "ackbar" > /dev/null 2>&1; then
    echo ""
    echo "⚠️  Ackbar is currently running. Please quit it first (Ctrl+C or pkill ackbar)"
    exit 1
fi

echo ""
echo "To enable keyboard shortcuts:"
echo ""
echo "1. Open System Settings"
echo "2. Go to Privacy & Security → Accessibility"
echo "3. Click the '+' button"
echo "4. Navigate to and add: $APP_PATH"
echo "5. Make sure the checkbox next to Ackbar is enabled"
echo ""
echo "Would you like to open System Settings now? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Opening System Settings..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    echo ""
    echo "After adding Ackbar to Accessibility:"
    echo "  1. Make sure it's checked ✓"
    echo "  2. Restart Ackbar"
    echo "  3. You should see '✓ Keyboard shortcuts enabled' in the output"
else
    echo ""
    echo "You can manually open:"
    echo "System Settings → Privacy & Security → Accessibility"
fi

echo ""
echo "Done! Remember to restart Ackbar after granting permissions."
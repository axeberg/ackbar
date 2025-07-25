#!/bin/bash

echo "🔍 Troubleshooting ackbar..."
echo

# Check Swift version
echo "1. Checking Swift installation:"
swift --version
echo

# Check if Ackbar is running
echo "2. Checking if Ackbar is running:"
if pgrep -x "ackbar" > /dev/null; then
    echo "   ✓ Ackbar is currently running"
else
    echo "   ✗ Ackbar is not running"
fi
echo

# Check accessibility permissions
echo "3. Checking accessibility permissions:"
if [[ -d "/Applications/Ackbar.app" ]]; then
    APP_PATH="/Applications/Ackbar.app"
elif command -v ackbar &> /dev/null; then
    APP_PATH=$(which ackbar)
else
    APP_PATH="Not found"
fi

if AXIsProcessTrusted > /dev/null 2>&1; then
    echo "   ✓ Accessibility permissions granted"
else
    echo "   ✗ Accessibility permissions not granted"
    echo "   To enable keyboard shortcuts, add $APP_PATH to:"
    echo "   System Settings → Privacy & Security → Accessibility"
fi
echo

# Check for conflicting apps
echo "4. Checking for apps that might interfere:"
ps aux | grep -E "(Bartender|Vanilla|Dozer|Hidden Bar)" | grep -v grep || echo "   No conflicting menu bar apps found"
echo

# Check saved preferences
echo "5. Checking saved preferences:"
echo "   Collapsed state: $(defaults read com.ackbar.isCollapsed 2>/dev/null || echo "not set")"
echo "   Auto-hide enabled: $(defaults read com.ackbar.autoHide 2>/dev/null || echo "not set")"
echo "   Auto-hide delay: $(defaults read com.ackbar.autoHideDelay 2>/dev/null || echo "not set")"
echo

# System info
echo "6. System information:"
sw_vers
echo

echo "✅ Troubleshooting complete"
echo
echo "Common issues:"
echo "  • Keyboard shortcuts not working: Grant accessibility permissions"
echo "  • Icons not hiding: Drag them to the LEFT of the separator"
echo "  • Separator hidden: Press ⌘⌃⌥M for emergency reset"

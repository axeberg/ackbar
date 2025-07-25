# Default recipe - show available commands
default:
    @just --list

# Build the binary
build:
    @echo "Building ackbar..."
    swiftc -O ackbar.swift -o ackbar
    chmod +x ackbar
    @echo "✓ Build complete"

# Install to /usr/local/bin
install: build
    @echo "Installing to /usr/local/bin..."
    sudo cp ackbar /usr/local/bin/ackbar
    @echo "✓ Installation complete"
    @echo "Run 'ackbar' to use"


# Uninstall from system
uninstall:
    @echo "Removing ackbar..."
    sudo rm -f /usr/local/bin/ackbar
    @echo "✓ Uninstalled"

# Run in test mode (shows red window)
test: build
    @echo "Running test mode..."
    @echo "You should see a RED window"
    ./ackbar --test

# Run normally
run: build
    ./ackbar

# Clean build artifacts
clean:
    rm -f ackbar ackbar-binary
    @echo "✓ Cleaned"

# Run linting checks
lint:
    @echo "Running SwiftLint..."
    @if command -v swiftlint &> /dev/null; then \
        swiftlint lint; \
    else \
        echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
    fi
    @echo ""
    @echo "Running SwiftFormat..."
    @if command -v swiftformat &> /dev/null; then \
        swiftformat --lint .; \
    else \
        echo "⚠️  SwiftFormat not installed. Install with: brew install swiftformat"; \
    fi

# Fix linting issues automatically
fix:
    @echo "Auto-fixing with SwiftLint..."
    @if command -v swiftlint &> /dev/null; then \
        swiftlint --fix --quiet || true; \
    else \
        echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
    fi
    @echo ""
    @echo "Formatting with SwiftFormat..."
    @if command -v swiftformat &> /dev/null; then \
        swiftformat . || true; \
    else \
        echo "⚠️  SwiftFormat not installed. Install with: brew install swiftformat"; \
    fi

# Run all CI checks locally
ci: lint build test ci-strict
    @echo "✅ All CI checks passed!"

# Run strict concurrency and analysis checks
ci-strict:
    @echo "Running strict concurrency checks..."
    swiftc -warnings-as-errors \
           -warn-concurrency \
           -enable-actor-data-race-checks \
           -strict-concurrency=complete \
           -target arm64-apple-macos15.0 \
           ackbar.swift -o /tmp/ackbar-analyzed
    @rm -f /tmp/ackbar-analyzed
    @echo "✓ Strict concurrency checks passed"

# Install development dependencies
deps:
    @echo "Installing development dependencies..."
    brew install swiftlint swiftformat
    @echo "✓ Dependencies installed"

# Install pre-commit hook
install-hooks:
    @echo "Installing pre-commit hook..."
    @ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
    @echo "✓ Pre-commit hook installed"

# Quick test without building
quick-test:
    swift ackbar.swift --test

# Troubleshoot issues
troubleshoot:
    @chmod +x scripts/troubleshoot.sh
    @./scripts/troubleshoot.sh

# Enable keyboard shortcuts
enable-shortcuts:
    @chmod +x scripts/enable-shortcuts.sh
    @./scripts/enable-shortcuts.sh


# Development - run with immediate compilation
dev:
    swift ackbar.swift

# Create release build
release: clean
    @echo "Creating release build..."
    swiftc -O -whole-module-optimization ackbar.swift -o ackbar
    strip ackbar
    @echo "✓ Release build ready"
    @ls -lh ackbar

# Build as macOS app bundle
app: clean
    @echo "Building Ackbar.app..."
    @mkdir -p Ackbar.app/Contents/MacOS
    @mkdir -p Ackbar.app/Contents/Resources
    @cp Info.plist Ackbar.app/Contents/
    @[ -f AppIcon.icns ] && cp AppIcon.icns Ackbar.app/Contents/Resources/ || true
    swiftc -O -whole-module-optimization ackbar.swift -o Ackbar.app/Contents/MacOS/ackbar
    @strip Ackbar.app/Contents/MacOS/ackbar
    @echo "✓ Ackbar.app built successfully"
    @echo "To install: just install-app"

# Install app to Applications folder
install-app: app
    @echo "Installing Ackbar.app to /Applications..."
    @rm -rf /Applications/Ackbar.app
    @cp -r Ackbar.app /Applications/
    @echo "✓ Ackbar.app installed"
    @echo "To start at login: just install-launch-agent"

# Install launch agent for auto-start
install-launch-agent:
    @echo "Installing launch agent..."
    @cp com.ackbar.app.plist ~/Library/LaunchAgents/
    @launchctl load ~/Library/LaunchAgents/com.ackbar.app.plist 2>/dev/null || true
    @echo "✓ Ackbar will start automatically at login"
    @echo "To remove: just uninstall-launch-agent"

# Uninstall launch agent
uninstall-launch-agent:
    @echo "Removing launch agent..."
    @launchctl unload ~/Library/LaunchAgents/com.ackbar.app.plist 2>/dev/null || true
    @rm -f ~/Library/LaunchAgents/com.ackbar.app.plist
    @echo "✓ Auto-start disabled"

#!/bin/bash
# Pre-commit hook for Ackbar
# Install with: ln -s ../../scripts/pre-commit.sh .git/hooks/pre-commit

set -e

echo "Running pre-commit checks..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "❌ SwiftLint not installed. Install with: brew install swiftlint"
    echo "   Or run: just deps"
    exit 1
fi

echo "→ Running SwiftLint..."
if ! swiftlint lint --quiet --reporter emoji; then
    echo "❌ SwiftLint found issues"
    exit 1
fi

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "❌ SwiftFormat not installed. Install with: brew install swiftformat"
    echo "   Or run: just deps"
    exit 1
fi

echo "→ Checking format..."
if ! swiftformat --lint . --quiet; then
    echo "❌ SwiftFormat found issues. Run: just fix"
    exit 1
fi

# Build check
echo "→ Building..."
if swiftc -warnings-as-errors -O ackbar.swift -o /tmp/ackbar-precommit; then
    echo "✓ Build successful"
    rm /tmp/ackbar-precommit
else
    echo "✗ Build failed"
    exit 1
fi

# Test CLI flags
echo "→ Testing CLI flags..."
if ./ackbar --test > /dev/null 2>&1; then
    echo "✓ Tests passed"
else
    echo "✗ Tests failed"
    exit 1
fi

echo "✅ All checks passed!"
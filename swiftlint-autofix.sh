#!/bin/bash

# SwiftLint Auto-Fix Script for FileOrganizer
# Automatically fixes common SwiftLint violations

set -e

echo "🔧 Running SwiftLint auto-fix..."

# Navigate to project directory
cd "$(dirname "$0")"

# Run SwiftLint autocorrect
if which swiftlint >/dev/null; then
    echo "📝 Auto-correcting SwiftLint violations..."
    swiftlint --fix --quiet
    
    echo "🧹 Running SwiftLint lint to check remaining issues..."
    swiftlint lint --reporter emoji --quiet | head -20
    
    echo "✅ SwiftLint auto-fix complete!"
else
    echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"
    exit 1
fi
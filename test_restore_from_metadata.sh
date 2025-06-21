#!/bin/bash

# test_restore_from_metadata.sh - Test restoration from metadata after nuke
# Usage: ./test_restore_from_metadata.sh [TARGET_FOLDER]

set -e

# Check if folder argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_folder>"
    echo "Example: $0 /path/to/folder"
    echo "Example: $0 ~/Downloads/messy_folder"
    exit 1
fi

TARGET_DIR="$1"

# Resolve to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

# Create Application Support path mirroring the target directory structure
TARGET_PATH_CLEAN=${TARGET_DIR#/}  # Remove leading slash
METADATA_DIR="/Users/cameronbrooks/Library/Application Support/FileOrganizer/RestoreManager/$TARGET_PATH_CLEAN"

echo "🔧 Testing restoration from metadata..."

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Find the newest metadata file (try .tsv first, fallback to .md)
METADATA_FILE=$(ls -t "$METADATA_DIR"/restore-*.tsv 2>/dev/null | head -1)
if [ -z "$METADATA_FILE" ]; then
    METADATA_FILE=$(ls -t "$METADATA_DIR"/restore-*.md 2>/dev/null | head -1)
fi

if [ -z "$METADATA_FILE" ]; then
    echo "❌ No metadata files found in: $METADATA_DIR"
    echo "Run ./test_create_metadata.sh first"
    exit 1
fi

echo "📄 Using metadata file: $(basename "$METADATA_FILE")"

# Show current chaos
echo "📊 Current folder state (after nuke):"
cd "$TARGET_DIR"
total_files=$(find . -type f -not -name ".*" | wc -l)
echo "Found $total_files files scattered across chaos"

# Parse metadata and attempt to restore files by name matching
echo "🔄 Attempting restoration..."

restored_count=0
error_count=0

# Read metadata file (skip comments)
while IFS=$'\t' read -r uuid original_path size; do
    # Skip comment lines
    if [[ "$uuid" =~ ^#.* ]]; then
        continue
    fi
    
    # Skip empty lines
    if [ -z "$uuid" ] || [ -z "$original_path" ]; then
        continue
    fi
    
    # Extract filename from original path
    filename=$(basename "$original_path")
    
    # Try to find file by name (since we can't use UUIDs in bash easily)
    current_file=$(find . -name "$filename" -type f | head -1)
    
    if [ -n "$current_file" ]; then
        # Calculate target path
        target_path="$original_path"
        target_dir=$(dirname "$target_path")
        
        # Create target directory if needed
        mkdir -p "$target_dir"
        
        # Check if target already exists
        if [ -f "$target_path" ] && [ "$current_file" != "./$target_path" ]; then
            echo "⚠️  Target exists, removing: $target_path"
            rm -f "$target_path"
        fi
        
        # Move file back (only if not already in place)
        if [ "$current_file" != "./$target_path" ]; then
            mv "$current_file" "$target_path"
            echo "✅ Restored: $original_path"
            restored_count=$((restored_count + 1))
        fi
    else
        echo "⚠️  Could not find file: $filename (original: $original_path)"
        error_count=$((error_count + 1))
    fi
    
done < "$METADATA_FILE"

# Clean up empty directories
echo "🧹 Cleaning up empty directories..."
find . -type d -empty -delete 2>/dev/null || true

echo ""
echo "🎉 Restoration complete!"
echo "📊 Results:"
echo "   - Files restored: $restored_count"
echo "   - Errors: $error_count"
echo ""
echo "📁 Final folder structure:"
tree -L 2 2>/dev/null || find . -type d | head -10
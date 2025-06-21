#!/bin/bash

# test_create_metadata.sh - Create restore metadata for testing
# Usage: ./test_create_metadata.sh [TARGET_FOLDER]

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

echo "🧪 Creating restore metadata for: $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Create metadata directory
mkdir -p "$METADATA_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
METADATA_FILE="$METADATA_DIR/restore-$TIMESTAMP.tsv"

echo "📝 Scanning files and creating metadata..."

# Create metadata file header
cat > "$METADATA_FILE" << EOF
# FileOrganizer Restore Metadata
# Created: $(date)
# Root: $TARGET_DIR
# Files: (counting...)
# Format: UUID<tab>OriginalPath<tab>Size

EOF

# Find all files and create metadata entries
file_count=0
cd "$TARGET_DIR"

find . -type f -not -path "./.restore*" | while read -r filepath; do
    # Remove leading ./
    clean_path=${filepath#./}
    
    # Generate UUID (simplified for bash)
    uuid=$(uuidgen)
    
    # Get file size
    size=$(stat -f%z "$filepath" 2>/dev/null || echo "0")
    
    # Add to metadata file
    echo -e "$uuid\t$clean_path\t$size" >> "$METADATA_FILE"
    
    file_count=$((file_count + 1))
done

# Update file count in header
total_files=$(grep -c $'\t' "$METADATA_FILE" || echo "0")
sed -i '' "s/# Files: (counting...)/# Files: $total_files/" "$METADATA_FILE"

echo "✅ Created metadata file: $METADATA_FILE"
echo "📊 Total files recorded: $total_files"
echo ""
echo "Next step: Run ./nuke.sh to destroy organization"
echo "Then run: ./test_restore_from_metadata.sh to test restoration"
#!/bin/bash

# nuke.sh - Completely destroys folder organization for RestoreManager testing
# Target: /Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer/realistic_110_files

set -e

TARGET_DIR="/Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer/realistic_110_files"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory does not exist: $TARGET_DIR"
    exit 1
fi

echo "💣 NUKE SCRIPT: Destroying folder organization in $TARGET_DIR"
echo "⚠️  WARNING: This will completely scramble the folder structure!"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

cd "$TARGET_DIR"

echo "🔥 Phase 1: Creating chaos folders..."
mkdir -p "TEMP_CHAOS_"{1..15}
mkdir -p "weird folder names with spaces and symbols!@#"
mkdir -p "тест/עברית/日本語/🤪🎉"
mkdir -p "deeply/nested/folder/structure/that/goes/way/too/deep/level10/level11/level12"

echo "🌪️  Phase 2: Renaming files with chaos..."
counter=1
find . -type f -not -path "./TEMP_CHAOS_*" -not -name ".*" | while read -r file; do
    if [ -f "$file" ]; then
        # Generate random chaotic name
        chaos_names=(
            "RENAMED_FILE_CHAOS_$counter"
            "什么鬼_file_$counter"
            "файл_хаос_$counter"
            "f!l3_w!th_$ymb0l$_$counter"
            "duplicate_name_$counter"
            "   spaces   and   tabs	_$counter"
            "VERY_LONG_FILENAME_THAT_KEEPS_GOING_AND_GOING_AND_GOING_$counter"
        )
        
        # Pick random name
        new_name=${chaos_names[$((RANDOM % ${#chaos_names[@]}))]}
        
        # Get original extension
        extension="${file##*.}"
        if [ "$extension" != "$(basename "$file")" ]; then
            new_name="$new_name.$extension"
        fi
        
        # Move to random chaos folder
        target_folder="TEMP_CHAOS_$((RANDOM % 15 + 1))"
        
        echo "Moving: $file -> $target_folder/$new_name"
        mv "$file" "$target_folder/$new_name" 2>/dev/null || true
        
        counter=$((counter + 1))
    fi
done

echo "🗂️  Phase 3: Creating nested chaos..."
# Move some chaos folders inside others
mv "TEMP_CHAOS_1"/* "deeply/nested/folder/structure/that/goes/way/too/deep/level10/level11/level12/" 2>/dev/null || true
mv "TEMP_CHAOS_2"/* "тест/עברית/日本語/🤪🎉/" 2>/dev/null || true
mv "TEMP_CHAOS_3"/* "weird folder names with spaces and symbols!@#/" 2>/dev/null || true

echo "🎭 Phase 4: More file moves for maximum chaos..."
# Find any remaining files and scatter them randomly
find . -type f -not -name ".*" | while read -r file; do
    if [ -f "$file" ]; then
        # Pick random destination
        destinations=(
            "deeply/nested/folder/structure/that/goes/way/too/deep/level10/level11/level12/"
            "тест/עברית/日本語/🤪🎉/"
            "weird folder names with spaces and symbols!@#/"
            "TEMP_CHAOS_$((RANDOM % 15 + 1))/"
        )
        
        dest=${destinations[$((RANDOM % ${#destinations[@]}))]}
        mkdir -p "$dest" 2>/dev/null || true
        
        # Sometimes duplicate the filename
        if [ $((RANDOM % 3)) -eq 0 ]; then
            cp "$file" "$dest/DUPLICATE_$(basename "$file")" 2>/dev/null || true
        fi
        
        mv "$file" "$dest/" 2>/dev/null || true
    fi
done

echo "🧹 Phase 5: Clean up empty chaos folders..."
rmdir TEMP_CHAOS_* 2>/dev/null || true

echo ""
echo "💥 NUKE COMPLETE! 💥"
echo "📊 Folder structure after nuking:"
echo "================================="
tree -L 3 2>/dev/null || find . -type d | head -20
echo ""
echo "🔧 Now test RestoreManager with:"
echo "   swift test_restore_from_nuke.swift"
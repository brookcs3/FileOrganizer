#!/usr/bin/env swift

import Foundation

// Test script for RestoreManager
let testFolderPath = "/Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer/realistic_110_files"
let testURL = URL(fileURLWithPath: testFolderPath)

print("🧪 Testing RestoreManager with folder: \(testFolderPath)")

// 1. Tag all files and create snapshots
print("\n📝 Step 1: Tagging files and creating snapshots...")
let snapshots = RestoreManager.tagAllFilesInTree(rootURL: testURL)
print("✅ Tagged \(snapshots.count) files with UUIDs")

// 2. Create restore file in Application Support
print("\n💾 Step 2: Creating restore file...")
let success = RestoreManager.createRestoreFile(at: testURL, snapshots: snapshots, useApplicationSupport: true)
if success {
    print("✅ Restore file created successfully")
} else {
    print("❌ Failed to create restore file")
    exit(1)
}

// 3. List the files for verification
print("\n📋 Step 3: Verifying restore files...")
let restoreFiles = RestoreManager.findRestoreFiles(for: testURL)
print("Found \(restoreFiles.count) restore files:")
for file in restoreFiles {
    print("  - \(file.url.path) (timestamp: \(file.timestamp))")
}

print("\n🎉 RestoreManager setup complete!")
print("Now run the nuke script to destroy the folder structure.")
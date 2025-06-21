#!/usr/bin/env swift

import Foundation

// Test script to restore from the chaos created by nuke.sh
let testFolderPath = "/Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer/realistic_110_files"
let testURL = URL(fileURLWithPath: testFolderPath)

print("🔧 Testing RestoreManager RESTORATION after nuke...")
print("Target folder: \(testFolderPath)")

// 1. Show current chaos
print("\n📊 Step 1: Current folder state (after nuke):")
let chaosFiles = RestoreManager.collectAllFilesRecursively(from: testURL)
print("Found \(chaosFiles.count) files scattered across the chaos")

// 2. Find restore files
print("\n🔍 Step 2: Looking for restore files...")
let restoreFiles = RestoreManager.findRestoreFiles(for: testURL)
if restoreFiles.isEmpty {
    print("❌ No restore files found! Did you run the initial test script?")
    exit(1)
}

print("Found \(restoreFiles.count) restore files:")
for file in restoreFiles {
    print("  - \(file.url.lastPathComponent) (timestamp: \(file.timestamp))")
}

// 3. Attempt restoration
print("\n🔄 Step 3: Attempting restoration...")
let success = RestoreManager.restoreFromSnapshot(at: testURL)

if success {
    print("✅ RESTORATION SUCCESSFUL!")
    
    // 4. Verify restoration
    print("\n📋 Step 4: Verifying restoration...")
    let restoredFiles = RestoreManager.collectAllFilesRecursively(from: testURL)
    print("Files after restoration: \(restoredFiles.count)")
    
    // Show structure
    print("\n📊 Final folder structure:")
    print("========================")
    // Note: We can't use tree here since this is just a Swift script
    // But we can show basic verification
    
    print("🎉 RestoreManager stress test COMPLETED!")
    print("Check the folder manually to verify all files are back in place.")
    
} else {
    print("❌ RESTORATION FAILED!")
    print("Some files could not be restored. Check the console output above for details.")
    exit(1)
}
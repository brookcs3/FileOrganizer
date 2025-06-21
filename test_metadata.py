#!/usr/bin/env python3

import os
import subprocess
import time

# Simple Python script to test the RestoreManager workflow
TEST_DIR = "/Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer/realistic_110_files"

def run_tree():
    """Show current folder structure"""
    try:
        result = subprocess.run(['tree', '-L', '2', TEST_DIR], 
                              capture_output=True, text=True)
        print(result.stdout)
    except FileNotFoundError:
        # Fallback if tree not available
        subprocess.run(['find', TEST_DIR, '-type', 'd', '|', 'head', '-20'], shell=True)

def main():
    print("🧪 RestoreManager Test Workflow")
    print("=" * 50)
    
    if not os.path.exists(TEST_DIR):
        print(f"❌ Test directory not found: {TEST_DIR}")
        return
    
    print(f"📁 Test directory: {TEST_DIR}")
    print("\n📊 Current structure:")
    run_tree()
    
    print("\n" + "=" * 50)
    print("MANUAL STEPS:")
    print("1. Use the FileOrganizer app to run RestoreManager.tagAllFilesInTree()")
    print("2. Run the nuke script: ./nuke.sh")  
    print("3. Use the app again to run RestoreManager.restoreFromSnapshot()")
    print("=" * 50)

if __name__ == "__main__":
    main()
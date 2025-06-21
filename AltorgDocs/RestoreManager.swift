//
//  RestoreManager.swift
//  FileSorter
//
//  Created by Cameron Brooks on 6/16/25.
//

import Foundation

class RestoreManager {
    private static let fileIdentifierKey = "com.filesorter.uuid"
    
    struct FileSnapshot {
        let uuid: String
        let originalPath: String
        let fileName: String
        let fileSize: Int64
        let creationDate: Date
        let modificationDate: Date
    }
    
    // MARK: - Extended Attributes
    
    static func setFileUUID(_ uuid: String, for url: URL) -> Bool {
        let path = url.path
        let result = setxattr(path, fileIdentifierKey, uuid, uuid.count, 0, 0)
        return result == 0
    }
    
    static func getFileUUID(for url: URL) -> String? {
        let path = url.path
        
        // First, get the size of the attribute
        let size = getxattr(path, fileIdentifierKey, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        
        // Allocate buffer with extra space for null terminator
        var buffer = [CChar](repeating: 0, count: size + 1)
        let result = getxattr(path, fileIdentifierKey, &buffer, size, 0, 0)
        guard result > 0 else { return nil }
        
        // Ensure null termination
        buffer[size] = 0
        
        return String(cString: buffer)
    }
    
    // MARK: - File Tree Processing
    
    static func tagAllFilesInTree(rootURL: URL) -> [FileSnapshot] {
        var snapshots: [FileSnapshot] = []
        let fileManager = FileManager.default
        
        func processDirectory(_ url: URL, relativePath: String = "") {
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .creationDateKey,
                .contentModificationDateKey
            ]) else { return }
            
            for case let fileURL as URL in enumerator {
                // Skip .restore.md files
                if fileURL.lastPathComponent == ".restore.md" { continue }
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [
                        .isDirectoryKey,
                        .fileSizeKey,
                        .creationDateKey,
                        .contentModificationDateKey
                    ])
                    
                    // Only process files, not directories
                    guard let isDirectory = resourceValues.isDirectory, !isDirectory else { continue }
                    
                    // Generate UUID if file doesn't have one
                    var uuid = getFileUUID(for: fileURL)
                    if uuid == nil {
                        uuid = UUID().uuidString
                        let success = setFileUUID(uuid!, for: fileURL)
                        if !success {
                            print("⚠️ Failed to set UUID for \(fileURL.path)")
                            continue
                        }
                    }
                    
                    // Calculate relative path from root
                    let fullPath = fileURL.path
                    let rootPath = rootURL.path
                    let relativePath = String(fullPath.dropFirst(rootPath.count + 1))
                    
                    let snapshot = FileSnapshot(
                        uuid: uuid!,
                        originalPath: relativePath,
                        fileName: fileURL.lastPathComponent,
                        fileSize: Int64(resourceValues.fileSize ?? 0),
                        creationDate: resourceValues.creationDate ?? Date(),
                        modificationDate: resourceValues.contentModificationDate ?? Date()
                    )
                    
                    snapshots.append(snapshot)
                    
                } catch {
                    print("⚠️ Error processing \(fileURL.path): \(error)")
                }
            }
        }
        
        processDirectory(rootURL)
        return snapshots
    }
    
    // MARK: - Homogeneous File Snapshot (identical to restore format)
    
    static func createHomogeneousSnapshot(at rootURL: URL, snapshots: [FileSnapshot]) -> Bool {
        let homogeneousURL = rootURL.appendingPathComponent(".restore-homogeneous.md")
        
        var content = """
        # FileSorter Homogeneous Snapshot
        
        Created: \(Date().formatted())
        Root Path: \(rootURL.path)
        Total Files: \(snapshots.count)
        
        ## File Mapping (UUID -> Original Path)
        
        """
        
        for snapshot in snapshots.sorted(by: { $0.originalPath < $1.originalPath }) {
            content += """
            ### \(snapshot.fileName)
            - **UUID**: `\(snapshot.uuid)`
            - **Path**: `\(snapshot.originalPath)`
            - **Size**: \(snapshot.fileSize) bytes
            - **Created**: \(snapshot.creationDate.formatted())
            - **Modified**: \(snapshot.modificationDate.formatted())
            
            """
        }
        
        do {
            try content.write(to: homogeneousURL, atomically: true, encoding: .utf8)
            lockFile(at: homogeneousURL)
            print("📸 Created homogeneous snapshot with \(snapshots.count) files")
            return true
        } catch {
            print("⚠️ Failed to create homogeneous snapshot: \(error)")
            return false
        }
    }
    
    // MARK: - Restore File Generation
    
    static func createRestoreFile(at rootURL: URL, snapshots: [FileSnapshot]) -> Bool {
        // Create timestamped restore file
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())
        let restoreFileName = ".restore-\(timestamp).md"
        let restoreURL = rootURL.appendingPathComponent(restoreFileName)
        
        var content = """
        # FileSorter Restore Snapshot
        
        Created: \(Date().formatted())
        Root Path: \(rootURL.path)
        Total Files: \(snapshots.count)
        
        ## File Mapping (UUID -> Original Path)
        
        """
        
        for snapshot in snapshots.sorted(by: { $0.originalPath < $1.originalPath }) {
            content += """
            ### \(snapshot.fileName)
            - **UUID**: `\(snapshot.uuid)`
            - **Path**: `\(snapshot.originalPath)`
            - **Size**: \(snapshot.fileSize) bytes
            - **Created**: \(snapshot.creationDate.formatted())
            - **Modified**: \(snapshot.modificationDate.formatted())
            
            """
        }
        
        do {
            try content.write(to: restoreURL, atomically: true, encoding: .utf8)
            
            // Lock the file to prevent accidental deletion
            lockFile(at: restoreURL)
            
            return true
        } catch {
            print("⚠️ Failed to create restore file: \(error)")
            return false
        }
    }
    
    // MARK: - File Locking
    
    private static func lockFile(at url: URL) {
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isUserImmutable = true
            var mutableURL = url
            try mutableURL.setResourceValues(resourceValues)
            print("🔒 Locked restore file: \(url.path)")
        } catch {
            print("⚠️ Failed to lock restore file: \(error)")
        }
    }
    
    static func unlockFile(at url: URL) {
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isUserImmutable = false
            var mutableURL = url
            try mutableURL.setResourceValues(resourceValues)
            print("🔓 Unlocked restore file: \(url.path)")
        } catch {
            print("⚠️ Failed to unlock restore file: \(error)")
        }
    }
    
    // MARK: - Restore File Discovery
    
    static func findAllRestoreFiles(at rootURL: URL) -> [(url: URL, timestamp: String)] {
        let fileManager = FileManager.default
        var restoreFiles: [(url: URL, timestamp: String)] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.creationDateKey])
            
            for file in contents {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix(".restore-") && fileName.hasSuffix(".md") {
                    // Extract timestamp from filename
                    let timestampPart = String(fileName.dropFirst(9).dropLast(3)) // Remove ".restore-" and ".md"
                    restoreFiles.append((url: file, timestamp: timestampPart))
                }
                // Also check for legacy .restore.md files
                else if fileName == ".restore.md" {
                    restoreFiles.append((url: file, timestamp: "legacy"))
                }
            }
            
            // Sort by timestamp (newest first)
            restoreFiles.sort { $0.timestamp > $1.timestamp }
            
        } catch {
            print("⚠️ Error finding restore files: \(error)")
        }
        
        return restoreFiles
    }
    
    // MARK: - Restore Process
    
    static func restoreFromSnapshot(at rootURL: URL, restoreFileURL: URL? = nil) -> Bool {
        let restoreFiles = findAllRestoreFiles(at: rootURL)
        
        guard !restoreFiles.isEmpty else {
            print("⚠️ No restore files found in \(rootURL.path)")
            return false
        }
        
        // Use specified restore file or default to newest
        let restoreURL = restoreFileURL ?? restoreFiles.first!.url
        
        print("🔄 Using restore file: \(restoreURL.lastPathComponent)")
        
        do {
            // Parse the restore file to get UUID -> path mappings
            let restoreContent = try String(contentsOf: restoreURL, encoding: .utf8)
            let snapshots = parseRestoreFile(content: restoreContent)
            
            print("🔄 Found \(snapshots.count) files to restore")
            
            // Find all current files and match them by UUID
            let allCurrentFiles = collectAllFilesRecursively(from: rootURL)
            var restoredCount = 0
            var errorCount = 0
            
            for snapshot in snapshots {
                // Find the current file with this UUID
                guard let currentFile = findFileByUUID(snapshot.uuid, in: allCurrentFiles) else {
                    print("⚠️ Could not find file with UUID \(snapshot.uuid) (original: \(snapshot.originalPath))")
                    errorCount += 1
                    continue
                }
                
                // Calculate the target path
                let targetURL = rootURL.appendingPathComponent(snapshot.originalPath)
                
                // Skip if already in correct location
                if currentFile == targetURL {
                    continue
                }
                
                // Create intermediate directories if needed
                let targetDirectory = targetURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Move the file back
                do {
                    // Remove target if it exists
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    
                    try FileManager.default.moveItem(at: currentFile, to: targetURL)
                    print("✅ Restored: \(snapshot.originalPath)")
                    restoredCount += 1
                    
                } catch {
                    print("⚠️ Failed to restore \(snapshot.originalPath): \(error)")
                    errorCount += 1
                }
            }
            
            // Clean up empty directories created during sorting
            cleanupEmptyDirectories(at: rootURL)
            
            print("🎉 Restore complete: \(restoredCount) files restored, \(errorCount) errors")
            return errorCount == 0
            
        } catch {
            print("⚠️ Failed to restore from snapshot: \(error)")
            return false
        }
    }
    
    // MARK: - Restore Helper Functions
    
    private static func parseRestoreFile(content: String) -> [FileSnapshot] {
        var snapshots: [FileSnapshot] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentFileName: String?
        var currentUUID: String?
        var currentPath: String?
        var currentSize: Int64 = 0
        let currentCreationDate = Date()
        let currentModificationDate = Date()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("### ") {
                // Save previous entry if complete
                if let fileName = currentFileName, let uuid = currentUUID, let path = currentPath {
                    snapshots.append(FileSnapshot(
                        uuid: uuid,
                        originalPath: path,
                        fileName: fileName,
                        fileSize: currentSize,
                        creationDate: currentCreationDate,
                        modificationDate: currentModificationDate
                    ))
                }
                
                // Start new entry
                currentFileName = String(trimmed.dropFirst(4))
                currentUUID = nil
                currentPath = nil
                currentSize = 0
                
            } else if trimmed.hasPrefix("- **UUID**: `") && trimmed.hasSuffix("`") {
                let start = trimmed.index(trimmed.startIndex, offsetBy: 13)
                let end = trimmed.index(trimmed.endIndex, offsetBy: -1)
                currentUUID = String(trimmed[start..<end])
                
            } else if trimmed.hasPrefix("- **Path**: `") && trimmed.hasSuffix("`") {
                let start = trimmed.index(trimmed.startIndex, offsetBy: 13)
                let end = trimmed.index(trimmed.endIndex, offsetBy: -1)
                currentPath = String(trimmed[start..<end])
                
            } else if trimmed.hasPrefix("- **Size**: ") && trimmed.contains(" bytes") {
                let sizeString = trimmed.replacingOccurrences(of: "- **Size**: ", with: "").replacingOccurrences(of: " bytes", with: "")
                currentSize = Int64(sizeString) ?? 0
            }
        }
        
        // Don't forget the last entry
        if let fileName = currentFileName, let uuid = currentUUID, let path = currentPath {
            snapshots.append(FileSnapshot(
                uuid: uuid,
                originalPath: path,
                fileName: fileName,
                fileSize: currentSize,
                creationDate: currentCreationDate,
                modificationDate: currentModificationDate
            ))
        }
        
        return snapshots
    }
    
    private static func collectAllFilesRecursively(from root: URL) -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []
        
        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }
        
        for case let url as URL in enumerator {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    // Skip .restore.md files
                    if url.lastPathComponent != ".restore.md" {
                        files.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        
        return files
    }
    
    private static func findFileByUUID(_ uuid: String, in files: [URL]) -> URL? {
        for file in files {
            if let fileUUID = getFileUUID(for: file), fileUUID == uuid {
                return file
            }
        }
        return nil
    }
    
    private static func cleanupEmptyDirectories(at root: URL) {
        let fileManager = FileManager.default
        
        // Get all directories, sorted by depth (deepest first)
        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else { return }
        
        var directories: [URL] = []
        for case let url as URL in enumerator {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    directories.append(url)
                }
            } catch {
                continue
            }
        }
        
        // Sort by path length (deepest first) to remove from leaves up
        directories.sort { $0.path.count > $1.path.count }
        
        for directory in directories {
            do {
                let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                if contents.isEmpty {
                    try fileManager.removeItem(at: directory)
                    print("🗑️ Removed empty directory: \(directory.lastPathComponent)")
                }
            } catch {
                // Directory not empty or other error, continue
                continue
            }
        }
    }
}

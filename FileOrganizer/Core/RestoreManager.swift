//
//  RestoreManager.swift
//  FileSorter
//
//  Created by Cameron Brooks on 6/16/25.
//

import Foundation

private enum RestoreConstants {
    static let restoreFileName = ".restore.md"
}

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

        processDirectory(rootURL, rootPath: rootURL.path, snapshots: &snapshots)
        return snapshots
    }

    private static func processDirectory(_ url: URL, rootPath: String, snapshots: inout [FileSnapshot]) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [
            .isDirectoryKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey
        ]) else { return }

        for case let fileURL as URL in enumerator {
            if shouldSkipFile(fileURL) { continue }

            do {
                if let snapshot = try createFileSnapshot(fileURL: fileURL, rootPath: rootPath) {
                    snapshots.append(snapshot)
                }
            } catch {
                print("⚠️ Error processing \(fileURL.path): \(error)")
            }
        }
    }

    private static func shouldSkipFile(_ fileURL: URL) -> Bool {
        return fileURL.lastPathComponent == RestoreConstants.restoreFileName
    }

    private static func createFileSnapshot(fileURL: URL, rootPath: String) throws -> FileSnapshot? {
        let resourceValues = try fileURL.resourceValues(forKeys: [
            .isDirectoryKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey
        ])

        // Only process files, not directories
        guard let isDirectory = resourceValues.isDirectory, !isDirectory else { return nil }

        // Ensure file has UUID
        guard let uuid = ensureFileHasUUID(fileURL) else { return nil }

        // Calculate relative path
        let relativePath = calculateRelativePath(fileURL: fileURL, rootPath: rootPath)

        return FileSnapshot(
            uuid: uuid,
            originalPath: relativePath,
            fileName: fileURL.lastPathComponent,
            fileSize: Int64(resourceValues.fileSize ?? 0),
            creationDate: resourceValues.creationDate ?? Date(),
            modificationDate: resourceValues.contentModificationDate ?? Date()
        )
    }

    private static func ensureFileHasUUID(_ fileURL: URL) -> String? {
        if let existingUUID = getFileUUID(for: fileURL) {
            return existingUUID
        }

        let newUUID = UUID().uuidString
        let success = setFileUUID(newUUID, for: fileURL)
        if !success {
            print("⚠️ Failed to set UUID for \(fileURL.path)")
            return nil
        }
        return newUUID
    }

    private static func calculateRelativePath(fileURL: URL, rootPath: String) -> String {
        let fullPath = fileURL.path
        return String(fullPath.dropFirst(rootPath.count + 1))
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

    static func createRestoreFile(at rootURL: URL, snapshots: [FileSnapshot], useApplicationSupport: Bool = true) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())

        let restoreURL: URL
        if useApplicationSupport {
            // Save to Application Support with mirrored directory structure
            restoreURL = createApplicationSupportPath(for: rootURL, timestamp: timestamp)
        } else {
            // Original behavior - save in folder
            let restoreFileName = ".restore-\(timestamp).md"
            restoreURL = rootURL.appendingPathComponent(restoreFileName)
        }

        // Create minimal TSV format - just the essentials
        var content = """
        # FileOrganizer Restore Metadata
        # Created: \(Date().formatted())
        # Root: \(rootURL.path)
        # Files: \(snapshots.count)
        # Format: UUID<tab>OriginalPath<tab>Size

        """

        for snapshot in snapshots.sorted(by: { $0.originalPath < $1.originalPath }) {
            content += "\(snapshot.uuid)\t\(snapshot.originalPath)\t\(snapshot.fileSize)\n"
        }

        do {
            // Ensure parent directory exists
            try FileManager.default.createDirectory(at: restoreURL.deletingLastPathComponent(),
                                                   withIntermediateDirectories: true)

            try content.write(to: restoreURL, atomically: true, encoding: .utf8)
            lockFile(at: restoreURL)

            print("📸 Restore file created: \(restoreURL.path)")
            return true
        } catch {
            print("⚠️ Failed to create restore file: \(error)")
            return false
        }
    }

    // MARK: - Application Support Integration

    private static func createApplicationSupportPath(for rootURL: URL, timestamp: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseURL = appSupport.appendingPathComponent("FileOrganizer/RestoreManager")

        // Mirror the directory structure
        var mirroredPath = rootURL.path
        if mirroredPath.hasPrefix("/") {
            mirroredPath = String(mirroredPath.dropFirst())
        }

        let mirroredURL = baseURL.appendingPathComponent(mirroredPath)
        let restoreFileName = "restore-\(timestamp).md"

        return mirroredURL.appendingPathComponent(restoreFileName)
    }

    // MARK: - Enhanced Restore File Discovery

    static func findRestoreFiles(for rootURL: URL, searchApplicationSupport: Bool = true) -> [(url: URL, timestamp: String)] {
        var restoreFiles: [(url: URL, timestamp: String)] = []

        if searchApplicationSupport {
            // Search Application Support first
            if let appSupportFiles = findApplicationSupportRestoreFiles(for: rootURL) {
                restoreFiles.append(contentsOf: appSupportFiles)
            }
        }

        // Also search original location as fallback
        let originalFiles = findAllRestoreFiles(at: rootURL)
        restoreFiles.append(contentsOf: originalFiles)

        // Sort by timestamp (newest first)
        return restoreFiles.sorted { $0.timestamp > $1.timestamp }
    }

    private static func findApplicationSupportRestoreFiles(for rootURL: URL) -> [(url: URL, timestamp: String)]? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseURL = appSupport.appendingPathComponent("FileOrganizer/RestoreManager")

        var mirroredPath = rootURL.path
        if mirroredPath.hasPrefix("/") {
            mirroredPath = String(mirroredPath.dropFirst())
        }

        let searchURL = baseURL.appendingPathComponent(mirroredPath)

        guard FileManager.default.fileExists(atPath: searchURL.path) else { return nil }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: searchURL, includingPropertiesForKeys: nil)
            var files: [(url: URL, timestamp: String)] = []

            for file in contents {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("restore-") && fileName.hasSuffix(".md") {
                    let timestampPart = String(fileName.dropFirst(8).dropLast(3)) // Remove "restore-" and ".md"
                    files.append((url: file, timestamp: timestampPart))
                }
            }

            return files
        } catch {
            print("⚠️ Error searching Application Support: \(error)")
            return nil
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
                else if fileName == RestoreConstants.restoreFileName {
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
        guard let restoreURL = selectRestoreFile(rootURL: rootURL, restoreFileURL: restoreFileURL) else {
            return false
        }

        do {
            let snapshots = try loadSnapshots(from: restoreURL)
            let result = restoreFiles(snapshots: snapshots, rootURL: rootURL)
            cleanupEmptyDirectories(at: rootURL)

            print("🎉 Restore complete: \(result.restoredCount) files restored, \(result.errorCount) errors")
            return result.errorCount == 0

        } catch {
            print("⚠️ Failed to restore from snapshot: \(error)")
            return false
        }
    }

    private static func selectRestoreFile(rootURL: URL, restoreFileURL: URL?) -> URL? {
        let restoreFiles = findRestoreFiles(for: rootURL)

        guard !restoreFiles.isEmpty else {
            print("⚠️ No restore files found for \(rootURL.path)")
            return nil
        }

        let restoreURL = restoreFileURL ?? restoreFiles.first!.url
        print("🔄 Using restore file: \(restoreURL.lastPathComponent)")
        return restoreURL
    }

    private static func loadSnapshots(from restoreURL: URL) throws -> [FileSnapshot] {
        let restoreContent = try String(contentsOf: restoreURL, encoding: .utf8)
        let snapshots = parseRestoreFile(content: restoreContent)
        print("🔄 Found \(snapshots.count) files to restore")
        return snapshots
    }

    private static func restoreFiles(snapshots: [FileSnapshot], rootURL: URL) -> (restoredCount: Int, errorCount: Int) {
        let allCurrentFiles = collectAllFilesRecursively(from: rootURL)
        var restoredCount = 0
        var errorCount = 0

        for snapshot in snapshots {
            let result = restoreSingleFile(snapshot: snapshot, rootURL: rootURL, allCurrentFiles: allCurrentFiles)
            restoredCount += result ? 1 : 0
            errorCount += result ? 0 : 1
        }

        return (restoredCount, errorCount)
    }

    private static func restoreSingleFile(snapshot: FileSnapshot, rootURL: URL, allCurrentFiles: [URL]) -> Bool {
        // Find the current file with this UUID
        guard let currentFile = findFileByUUID(snapshot.uuid, in: allCurrentFiles) else {
            print("⚠️ Could not find file with UUID \(snapshot.uuid) (original: \(snapshot.originalPath))")
            return false
        }

        let targetURL = rootURL.appendingPathComponent(snapshot.originalPath)

        // Skip if already in correct location
        if currentFile == targetURL { return true }

        return moveFileToTarget(currentFile: currentFile, targetURL: targetURL, originalPath: snapshot.originalPath)
    }

    private static func moveFileToTarget(currentFile: URL, targetURL: URL, originalPath: String) -> Bool {
        do {
            // Create intermediate directories if needed
            let targetDirectory = targetURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)

            // Remove target if it exists
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }

            try FileManager.default.moveItem(at: currentFile, to: targetURL)
            print("✅ Restored: \(originalPath)")
            return true

        } catch {
            print("⚠️ Failed to restore \(originalPath): \(error)")
            return false
        }
    }

    // MARK: - Restore Helper Functions

    private static func parseRestoreFile(content: String) -> [FileSnapshot] {
        var snapshots: [FileSnapshot] = []
        let lines = content.components(separatedBy: .newlines)

        // Detect format: TSV (new) or Markdown (legacy)
        let isTSVFormat = content.contains("Format: UUID<tab>OriginalPath")

        if isTSVFormat {
            // Parse minimal TSV format
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Skip comments and empty lines
                if trimmed.hasPrefix("#") || trimmed.isEmpty {
                    continue
                }

                let parts = trimmed.components(separatedBy: "\t")
                if parts.count >= 3 {
                    let uuid = parts[0]
                    let originalPath = parts[1]
                    let fileSize = Int64(parts[2]) ?? 0

                    // Extract filename from path
                    let fileName = (originalPath as NSString).lastPathComponent

                    // Use current time as placeholder for dates (not critical for restoration)
                    let currentDate = Date()

                    snapshots.append(FileSnapshot(
                        uuid: uuid,
                        originalPath: originalPath,
                        fileName: fileName,
                        fileSize: fileSize,
                        creationDate: currentDate,
                        modificationDate: currentDate
                    ))
                }
            }
        } else {
            // Parse legacy Markdown format
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
                    if url.lastPathComponent != RestoreConstants.restoreFileName {
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

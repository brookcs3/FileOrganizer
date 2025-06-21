//
//  RestoreManager.swift
//  FileSorter
//
//  Created by Cameron Brooks on 6/16/25.
//

import Foundation

// MARK: - Restore Constants
private enum RestoreConstants {
    static let restoreFileName = ".restore.md"
}

// MARK: - Restore Manager
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

    // MARK: - Extended Attributes (Delegated to RestoreMetadata)

    static func setFileUUID(_ uuid: String, for url: URL) -> Bool {
        RestoreMetadata.setFileUUID(uuid, for: url)
    }

    static func getFileUUID(for url: URL) -> String? {
        RestoreMetadata.getFileUUID(for: url)
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
        fileURL.lastPathComponent == RestoreConstants.restoreFileName
    }

    private static func createFileSnapshot(fileURL: URL, rootPath: String) throws -> FileSnapshot? {
        guard let tuple = try RestoreMetadata.createFileSnapshot(fileURL: fileURL, rootPath: rootPath) else { return nil }
        return FileSnapshot(
            uuid: tuple.uuid,
            originalPath: tuple.originalPath,
            fileName: tuple.fileName,
            fileSize: tuple.fileSize,
            creationDate: tuple.creationDate,
            modificationDate: tuple.modificationDate
        )
    }

    // MARK: - Homogeneous File Snapshot (identical to restore format)

    static func createHomogeneousSnapshot(at rootURL: URL, snapshots: [FileSnapshot]) -> Bool {
        let tuples = snapshots.map { snapshot in
            (uuid: snapshot.uuid, originalPath: snapshot.originalPath, fileName: snapshot.fileName, 
             fileSize: snapshot.fileSize, creationDate: snapshot.creationDate, modificationDate: snapshot.modificationDate)
        }
        return RestoreFileWriter.createHomogeneousSnapshot(at: rootURL, snapshots: tuples)
    }

    // MARK: - Restore File Generation

    static func createRestoreFile(at rootURL: URL, snapshots: [FileSnapshot], useApplicationSupport: Bool = true) -> Bool {
        let tuples = snapshots.map { snapshot in
            (uuid: snapshot.uuid, originalPath: snapshot.originalPath, fileName: snapshot.fileName,
             fileSize: snapshot.fileSize, creationDate: snapshot.creationDate, modificationDate: snapshot.modificationDate) 
        }
        return RestoreFileWriter.createRestoreFile(at: rootURL, snapshots: tuples, useApplicationSupport: useApplicationSupport)
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
        let tuples = RestoreFileParser.parseRestoreFile(content: content)
        return tuples.map { tuple in
            FileSnapshot(
                uuid: tuple.uuid,
                originalPath: tuple.originalPath,
                fileName: tuple.fileName,
                fileSize: tuple.fileSize,
                creationDate: tuple.creationDate,
                modificationDate: tuple.modificationDate
            )
        }
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

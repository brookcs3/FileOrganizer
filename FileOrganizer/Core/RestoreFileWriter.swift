//
//  RestoreFileWriter.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import Foundation

/// Handles creation and writing of restore files
struct RestoreFileWriter {
    /// Creates a restore file with snapshot data
    static func createRestoreFile(at rootURL: URL, snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)], useApplicationSupport: Bool = true) -> Bool {
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
        let content = generateTSVContent(rootURL: rootURL, snapshots: snapshots)
        
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
    
    /// Creates homogeneous snapshot file
    static func createHomogeneousSnapshot(at rootURL: URL, snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)]) -> Bool {
        let homogeneousURL = rootURL.appendingPathComponent(".restore-homogeneous.md")
        
        let content = generateHomogeneousContent(rootURL: rootURL, snapshots: snapshots)
        
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
    
    // MARK: - Content Generation
    
    private static func generateTSVContent(rootURL: URL, snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)]) -> String {
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
        
        return content
    }
    
    private static func generateHomogeneousContent(rootURL: URL, snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)]) -> String {
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
        
        return content
    }
    
    // MARK: - Path Management
    
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
}

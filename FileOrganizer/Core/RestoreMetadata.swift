//
//  RestoreMetadata.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import Foundation

/// Handles extended attributes and UUID management for files
struct RestoreMetadata {
    private static let fileIdentifierKey = "com.filesorter.uuid"
    
    // MARK: - Extended Attributes
    
    /// Sets a UUID as an extended attribute on a file
    static func setFileUUID(_ uuid: String, for url: URL) -> Bool {
        let path = url.path
        let result = setxattr(path, fileIdentifierKey, uuid, uuid.count, 0, 0)
        return result == 0
    }
    
    /// Retrieves the UUID extended attribute from a file
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
    
    /// Ensures a file has a UUID, creating one if needed
    static func ensureFileHasUUID(_ fileURL: URL) -> String? {
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
    
    // MARK: - File Snapshot Creation
    
    /// Creates a file snapshot with metadata
    static func createFileSnapshot(fileURL: URL, rootPath: String) throws -> (uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)? {
        let resourceValues = try fileURL.resourceValues(forKeys: [
            .isDirectoryKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey
        ])
        
        // Only process files, not directories
        guard let isDirectory = resourceValues.isDirectory, !isDirectory else { return nil }
        
        // Ensure file has UUID
        guard let uuid = ensureFileHasUUID(fileURL) else { return nil }
        
        // Calculate relative path
        let relativePath = calculateRelativePath(fileURL: fileURL, rootPath: rootPath)
        
        return (
            uuid: uuid,
            originalPath: relativePath,
            fileName: fileURL.lastPathComponent,
            fileSize: Int64(resourceValues.fileSize ?? 0),
            creationDate: resourceValues.creationDate ?? Date(),
            modificationDate: resourceValues.contentModificationDate ?? Date()
        )
    }
    
    // MARK: - Path Utilities
    
    private static func calculateRelativePath(fileURL: URL, rootPath: String) -> String {
        let fullPath = fileURL.path
        return String(fullPath.dropFirst(rootPath.count + 1))
    }
}

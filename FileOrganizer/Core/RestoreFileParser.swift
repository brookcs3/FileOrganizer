//
//  RestoreFileParser.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import Foundation

/// Handles parsing of restore files in both TSV and legacy Markdown formats
struct RestoreFileParser {
    /// Parses restore file content and returns array of FileSnapshot tuples
    static func parseRestoreFile(content: String) -> [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] {
        var snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Detect format: TSV (new) or Markdown (legacy)
        let isTSVFormat = content.contains("Format: UUID<tab>OriginalPath")
        
        if isTSVFormat {
            snapshots = parseTSVFormat(lines: lines)
        } else {
            snapshots = parseMarkdownFormat(lines: lines)
        }
        
        return snapshots
    }
    
    // MARK: - TSV Format Parsing
    
    private static func parseTSVFormat(lines: [String]) -> [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] {
        var snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] = []
        
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
                
                snapshots.append((
                    uuid: uuid,
                    originalPath: originalPath,
                    fileName: fileName,
                    fileSize: fileSize,
                    creationDate: currentDate,
                    modificationDate: currentDate
                ))
            }
        }
        
        return snapshots
    }
    
    // MARK: - Markdown Format Parsing
    
    private static func parseMarkdownFormat(lines: [String]) -> [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] {
        var snapshots: [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)] = []
        var currentState = MarkdownParseState()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("### ") {
                saveCurrentEntryIfComplete(&snapshots, state: currentState)
                currentState.startNewEntry(fileName: String(trimmed.dropFirst(4)))
            } else {
                parseMarkdownLine(trimmed, into: &currentState)
            }
        }
        
        saveCurrentEntryIfComplete(&snapshots, state: currentState)
        return snapshots
    }
    
    private static func saveCurrentEntryIfComplete(_ snapshots: inout [(uuid: String, originalPath: String, fileName: String, fileSize: Int64, creationDate: Date, modificationDate: Date)], state: MarkdownParseState) {
        if let fileName = state.fileName, let uuid = state.uuid, let path = state.path {
            snapshots.append((
                uuid: uuid,
                originalPath: path,
                fileName: fileName,
                fileSize: state.size,
                creationDate: state.creationDate,
                modificationDate: state.modificationDate
            ))
        }
    }
    
    private static func parseMarkdownLine(_ trimmed: String, into state: inout MarkdownParseState) {
        if trimmed.hasPrefix("- **UUID**: `") && trimmed.hasSuffix("`") {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 13)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -1)
            state.uuid = String(trimmed[start..<end])
        } else if trimmed.hasPrefix("- **Path**: `") && trimmed.hasSuffix("`") {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 13)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -1)
            state.path = String(trimmed[start..<end])
        } else if trimmed.hasPrefix("- **Size**: ") && trimmed.contains(" bytes") {
            let sizeString = trimmed.replacingOccurrences(of: "- **Size**: ", with: "").replacingOccurrences(of: " bytes", with: "")
            state.size = Int64(sizeString) ?? 0
        }
    }
}

private struct MarkdownParseState {
    var fileName: String?
    var uuid: String?
    var path: String?
    var size: Int64 = 0
    let creationDate = Date()
    let modificationDate = Date()
    
    mutating func startNewEntry(fileName: String) {
        self.fileName = fileName
        self.uuid = nil
        self.path = nil
        self.size = 0
    }
}

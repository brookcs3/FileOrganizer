//
//  AltFileProcessor.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/20/25.
//
//  ALT ORGANIZE: Token-safe bulk mapping approach
//  Uses UUID-based mapping documents for instant organization
//

import Foundation
import FoundationModels
import SwiftUI
import Observation

@available(macOS 26.0, *)
@MainActor
@Observable
class AltFileProcessor {
    var isProcessing = false
    var progress: Double = 0.0
    var currentStatus = ""
    
    var foundationModelsManager: FoundationModelsManager
    private let fileManager = FileManager.default
    
    init(foundationModelsManager: FoundationModelsManager) {
        self.foundationModelsManager = foundationModelsManager
    }
    
    // MARK: - Main ALT Processing Function
    func processDirectoryAlt(_ directoryURL: URL) async throws -> OrganizationResult {
        let startTime = Date()
        isProcessing = true
        progress = 0
        currentStatus = "Starting ALT organization..."
        
        // ── 1. Generate tree structure for AI context ──────────────────────
        currentStatus = "Analyzing folder structure..."
        progress = 0.1
        
        let treeStructure = try await generateTreeStructure(directoryURL)
        
        // ── 2. Tag all files with UUIDs and create manifest ──────────────────
        currentStatus = "Tagging files and building manifest..."
        progress = 0.2
        
        let snapshots = RestoreManager.tagAllFilesInTree(rootURL: directoryURL)
        let manifest = buildManifest(from: snapshots, root: directoryURL)
        
        // ── 3. Create mapping document template ──────────────────────────────
        currentStatus = "Creating mapping document..."
        progress = 0.3
        
        let mappingDoc = createMappingDocument(manifest: manifest, treeStructure: treeStructure)
        
        // ── 4. Chunk document if needed ─────────────────────────────────────
        let chunks = chunkMappingDocument(mappingDoc)
        currentStatus = "Processing \(chunks.count) mapping chunks..."
        
        // ── 5. AI fills out the mapping ─────────────────────────────────────
        var completedMapping: [String: String] = [:]  // UUID -> newPath
        
        for (index, chunk) in chunks.enumerated() {
            currentStatus = "AI mapping chunk \(index + 1)/\(chunks.count)..."
            progress = 0.4 + (0.4 * Double(index) / Double(chunks.count))
            
            let chunkMapping = try await processChunkWithAI(chunk: chunk, 
                                                           chunkIndex: index,
                                                           totalChunks: chunks.count,
                                                           existingMapping: completedMapping)
            completedMapping.merge(chunkMapping) { _, new in new }
        }
        
        // ── 6. Execute instant bulk moves ───────────────────────────────────
        currentStatus = "Executing bulk file moves..."
        progress = 0.8
        
        let execResult = try await executeBulkMoves(mapping: completedMapping, 
                                                   snapshots: snapshots, 
                                                   rootURL: directoryURL)
        
        // ── 7. Create restore snapshot ──────────────────────────────────────
        currentStatus = "Creating restore snapshot..."
        progress = 0.9
        
        _ = RestoreManager.createRestoreFile(at: directoryURL, snapshots: snapshots)
        
        currentStatus = "Complete"
        progress = 1.0
        isProcessing = false
        
        return OrganizationResult(
            sourceDirectory: directoryURL.path,
            targetDirectory: directoryURL.path,
            mode: "ALT Token-Safe",
            filesProcessed: snapshots.count,
            filesOrganized: execResult.filesOrganized,
            categoriesCreated: execResult.categoriesCreated,
            duration: Date().timeIntervalSince(startTime)
        )
    }
    
    // MARK: - Tree Structure Generation
    private func generateTreeStructure(_ directoryURL: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Use tree command if available, otherwise fall back to Swift implementation
                    let treeOutput = try self.runTreeCommand(at: directoryURL.path)
                    continuation.resume(returning: treeOutput)
                } catch {
                    // Fallback to Swift-based tree generation
                    let swiftTree = self.generateSwiftTree(at: directoryURL)
                    continuation.resume(returning: swiftTree)
                }
            }
        }
    }
    
    nonisolated private func runTreeCommand(at path: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tree")
        process.arguments = ["-a", "--noreport", "-L", "3", path]  // Limit depth to 3 for token safety
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    nonisolated private func generateSwiftTree(at url: URL, depth: Int = 0, maxDepth: Int = 3) -> String {
        guard depth <= maxDepth else { return "" }
        
        var result = ""
        let indent = String(repeating: "  ", count: depth)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            
            for (index, item) in contents.enumerated() {
                let isLast = index == contents.count - 1
                let prefix = isLast ? "└── " : "├── "
                result += "\(indent)\(prefix)\(item.lastPathComponent)\n"
                
                let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
                if resourceValues.isDirectory == true && depth < maxDepth {
                    result += generateSwiftTree(at: item, depth: depth + 1, maxDepth: maxDepth)
                }
            }
        } catch {
            result += "\(indent)Error reading directory\n"
        }
        
        return result
    }
    
    // MARK: - Manifest Building
    private func buildManifest(from snapshots: [RestoreManager.FileSnapshot], root: URL) -> [FileManifestEntry] {
        return snapshots.map { snapshot in
            FileManifestEntry(
                uuid: snapshot.uuid,
                originalPath: snapshot.originalPath,
                fileName: snapshot.fileName,
                size: snapshot.fileSize,
                modificationDate: snapshot.modificationDate
            )
        }
    }
    
    // MARK: - Mapping Document Creation
    private func createMappingDocument(manifest: [FileManifestEntry], treeStructure: String) -> String {
        var doc = """
        # FOLDER ORGANIZATION MAPPING
        
        ## CURRENT STRUCTURE:
        \(treeStructure)
        
        ## FILE MAPPING (UUID → New Path):
        Instructions: For each file below, suggest a clean organizational path.
        Format: UUID | current_name | size | date → NEW_PATH
        
        """
        
        for entry in manifest {
            doc += "\(entry.uuid) | \(entry.fileName) | \(entry.size) bytes | \(entry.modificationDate.formatted(date: .abbreviated, time: .omitted)) → \n"
        }
        
        return doc
    }
    
    // MARK: - Document Chunking
    private func chunkMappingDocument(_ document: String) -> [String] {
        let lines = document.components(separatedBy: .newlines)
        let headerLines = lines.prefix(while: { !$0.contains("→") })
        let mappingLines = lines.drop(while: { !$0.contains("→") })
        
        let maxLinesPerChunk = 200  // Conservative for token safety
        var chunks: [String] = []
        
        for chunk in Array(mappingLines).chunked(into: maxLinesPerChunk) {
            var chunkDoc = headerLines.joined(separator: "\n")
            chunkDoc += "\n\n"
            chunkDoc += chunk.joined(separator: "\n")
            chunks.append(chunkDoc)
        }
        
        return chunks.isEmpty ? [document] : chunks
    }
    
    // MARK: - AI Processing
    private func processChunkWithAI(chunk: String, chunkIndex: Int, totalChunks: Int, existingMapping: [String: String]) async throws -> [String: String] {
        
        guard let sessionPool = foundationModelsManager.sessionPool else {
            throw NSError(domain: "AltFileProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "sessionPool was nil"])
        }
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }
        
        var contextPrompt = """
        You are an expert file organizer. Complete the mapping document by filling in NEW_PATH for each file.
        
        Rules:
        - Suggest clean, logical folder structures
        - Use categories like: Documents/, Photos/, Music/, Videos/, Archive/, etc.
        - Group by type, date, or project as appropriate
        - Keep paths concise but descriptive
        - Format: exactly as shown, just add the path after →
        """
        
        // Add context from previous chunks
        if !existingMapping.isEmpty {
            let existingFolders = Set(existingMapping.values.map { ($0 as NSString).deletingLastPathComponent })
            contextPrompt += "\n\nExisting folders from previous chunks: \(existingFolders.sorted().joined(separator: ", "))"
        }
        
        if totalChunks > 1 {
            contextPrompt += "\n\nThis is chunk \(chunkIndex + 1) of \(totalChunks)."
        }
        
        let response = try await session.respond(
            to: contextPrompt + "\n\n" + chunk,
            options: GenerationOptions(temperature: 0.3)
        )
        
        return parseMappingResponse(response.content)
    }
    
    private func parseMappingResponse(_ response: String) -> [String: String] {
        var mapping: [String: String] = [:]
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("→") {
                let parts = line.components(separatedBy: "→")
                if parts.count >= 2 {
                    let leftPart = parts[0].trimmingCharacters(in: .whitespaces)
                    let rightPart = parts[1].trimmingCharacters(in: .whitespaces)
                    
                    // Extract UUID from left part (first component before |)
                    if let uuid = leftPart.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces),
                       !rightPart.isEmpty {
                        mapping[uuid] = rightPart
                    }
                }
            }
        }
        
        return mapping
    }
    
    // MARK: - Bulk Execution
    private func executeBulkMoves(mapping: [String: String], snapshots: [RestoreManager.FileSnapshot], rootURL: URL) async throws -> (filesOrganized: Int, categoriesCreated: [String]) {
        
        var filesOrganized = 0
        var categoriesCreated: Set<String> = []
        
        // Create all target directories first
        for targetPath in mapping.values {
            let targetURL = rootURL.appendingPathComponent(targetPath)
            let targetDir = targetURL.deletingLastPathComponent()
            
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            categoriesCreated.insert(targetDir.lastPathComponent)
        }
        
        // Execute moves
        for snapshot in snapshots {
            if let newPath = mapping[snapshot.uuid] {
                let currentURL = rootURL.appendingPathComponent(snapshot.originalPath)
                let targetURL = rootURL.appendingPathComponent(newPath)
                
                // Check if file still exists at original location
                if fileManager.fileExists(atPath: currentURL.path) {
                    try fileManager.moveItem(at: currentURL, to: targetURL)
                    filesOrganized += 1
                }
            }
        }
        
        return (filesOrganized: filesOrganized, categoriesCreated: Array(categoriesCreated))
    }
}

// MARK: - Supporting Data Structures
struct FileManifestEntry {
    let uuid: String
    let originalPath: String
    let fileName: String
    let size: Int64
    let modificationDate: Date
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

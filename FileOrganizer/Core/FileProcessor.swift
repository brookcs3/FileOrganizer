//
//  FileProcessor.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Core file processing engine implementing token-safe methodology
//  with Apple Foundation Models for token-safe analysis
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import Combine
import FoundationModels          // ← add this line
import OSLog
import Observation

@available(macOS 26.0, *)
@MainActor
@Observable
class FileProcessor {

    var isProcessing = false
    var progress: Double = 0.0
    var currentStatus = ""

    var foundationModelsManager: FoundationModelsManager
    private let fileManager = FileManager.default

    init(foundationModelsManager: FoundationModelsManager) {
        self.foundationModelsManager = foundationModelsManager
    }

    // MARK: - Main Processing Functions
    func processDirectory(_ directoryURL: URL) async throws -> OrganizationResult {
        // ── Security-scoped URL bookkeeping ───────────────────────────────
        guard let bookmarkData = UserDefaults.standard.data(forKey: "selectedFolderBookmark") else {
            throw NSError(domain: "FileOrganizerError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No bookmark found"])
        }
        var isStale = false
        let secureURL = try URL(resolvingBookmarkData: bookmarkData,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
        guard secureURL.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "FileOrganizerError", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to access directory"])
        }
        defer { secureURL.stopAccessingSecurityScopedResource() }

        // ── UI state prep ────────────────────────────────────────────────
        let startTime = Date()
        isProcessing  = true
        progress      = 0
        currentStatus = "Scanning directory..."

        // ── 1. Discover files ───────────────────────────────
        let fileItems = try await discoverFiles(in: directoryURL)

        currentStatus = "Found \(fileItems.count) files"
        progress = 0.1

        // ── 2. Analyse each file ───────────────────────────────
        var processedFiles: [FileItem?] = Array(repeating: nil, count: fileItems.count)
        let total = fileItems.count
        var completedCount = 0

        await withTaskGroup(of: (Int, FileItem).self) { group in
            var inFlight = 0
            var fileIterator = fileItems.enumerated().makeIterator()

            // Fill the group up to 3 concurrent tasks
            while inFlight < 3, let (index, file) = fileIterator.next() {
                group.addTask {
                    var mutableFile = file
                    // Create a new independent AI session for this task
                    let aiSession = await self.foundationModelsManager.makeNewSession() // <-- per-task
                    mutableFile.analysisResult = try? await aiSession.analyzeFileContent(
                        try await self.extractFileContent(mutableFile),
                        fileName: mutableFile.name,
                        fileType: mutableFile.type
                    )
                    if let meta = mutableFile.analysisResult {
                        do {
                            try await DirectorySummarySession.shared.add(FileMetadata(
                                primaryCategory: meta.category,
                                secondaryCategory: meta.subcategory,
                                suggestedFilename: meta.suggestedName,
                                summary: meta.description,
                                tags: meta.tags,
                                confidence: meta.confidence
                            ))
                        } catch {
                            print("Summary update failed for \(file.name): \(error)")
                        }
                    }
                    // Simulate pacing
                    try? await Task.sleep(nanoseconds: 10_000_000)
                    return (index, mutableFile)
                }
                inFlight += 1
            }

            for await (index, resultFile) in group {
                processedFiles[index] = resultFile
                completedCount += 1
                progress = 0.1 + 0.7 * Double(completedCount) / Double(total)

                // Always keep up to 3 tasks in flight
                if let (nextIndex, nextFile) = fileIterator.next() {
                    group.addTask {
                        var mutableFile = nextFile
                        // Create a new independent AI session for this task
                        let aiSession = await self.foundationModelsManager.makeNewSession() // <-- per-task session creation
                        mutableFile.analysisResult = try? await aiSession.analyzeFileContent(
                            try await self.extractFileContent(mutableFile),
                            fileName: mutableFile.name,
                            fileType: mutableFile.type
                        )
                        if let meta = mutableFile.analysisResult {
                            do {
                                try await DirectorySummarySession.shared.add(FileMetadata(
                                    primaryCategory: meta.category,
                                    secondaryCategory: meta.subcategory,
                                    suggestedFilename: meta.suggestedName,
                                    summary: meta.description,
                                    tags: meta.tags,
                                    confidence: meta.confidence
                                ))
                            } catch {
                                print("Summary update failed for \(nextFile.name): \(error)")
                            }
                        }
                        try? await Task.sleep(nanoseconds: 10_000_000)
                        return (nextIndex, mutableFile)
                    }
                }
            }
        }
        // Remove optionals after all tasks complete
        let processedFilesNonNil = processedFiles.compactMap { $0 }

        // ── 3. Create & execute organization plan ───────────────────────
        currentStatus = "Creating organization plan..."
        progress      = 0.8

        let plan = createOrganizationPlan(files: processedFilesNonNil,
                                          sourceDirectory: directoryURL)

        currentStatus = "Executing organization..."
        progress      = 0.9

        let execResult = try await executeOrganization(plan: plan)

        progress      = 1
        currentStatus = "Complete"

        // —— NEW: directory-level advice ——————————
        let advice: String
        do {
            advice = try await DirectorySummarySession.shared.globalAdvice()
            Logger().info("Continuity advice: \(advice)")
        } catch {
            advice = "No advice (error: \(error.localizedDescription))"
        }
        // ————————————————————————————————

        // ── 4. Return summary object ────────────────────────────────────
        return OrganizationResult(
            sourceDirectory: directoryURL.path,
            targetDirectory: plan.targetDirectory.path,
            mode: SortingMode.name,
            filesProcessed: total,
            filesOrganized: execResult.filesOrganized,
            categoriesCreated: execResult.categoriesCreated,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - File Discovery (QiuYannnn approach)

    private func discoverFiles(in directoryURL: URL) async throws -> [FileItem] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let resourceKeys: [URLResourceKey] = [
                        .isRegularFileKey,
                        .fileSizeKey,
                        .contentModificationDateKey,
                        .typeIdentifierKey
                    ]

                    let enumerator = FileManager.default.enumerator(
                        at: directoryURL,
                        includingPropertiesForKeys: resourceKeys,
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]
                    )

                    var fileItems: [FileItem] = []

                    while let url = enumerator?.nextObject() as? URL {
                        let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))

                        guard resourceValues.isRegularFile == true else { continue }

                        let fileItem = FileItem(
                            url: url,
                            name: url.lastPathComponent,
                            type: url.pathExtension,
                            size: Int64(resourceValues.fileSize ?? 0),
                            modificationDate: resourceValues.contentModificationDate ?? Date()
                        )

                        fileItems.append(fileItem)
                    }

                    continuation.resume(returning: fileItems)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Quickly scans the given directory and returns the count of each file type.
    private func countFileTypes(in directoryURL: URL) async throws -> [String: Int] {
        let files = try await discoverFiles(in: directoryURL)
        var typeCounts: [String: Int] = [:]
        for file in files {
            typeCounts[file.type, default: 0] += 1
        }
        return typeCounts
    }

    // MARK: - AI Analysis (Token-Safe)

    // This method is no longer used directly in the task; analysis now happens inside the task with a per-task session.
    private func analyzeFileWithAI(_ fileItem: FileItem) async throws -> FileAnalysisResult {
        // Extract content based on file type
        let content = try await extractFileContent(fileItem)

        // Use Foundation Models for analysis
        return try await foundationModelsManager.analyzeFileContent(
            content,
            fileName: fileItem.name,
            fileType: fileItem.type
        )
    }

    private func extractFileContent(_ fileItem: FileItem) async throws -> String {
        let fileType = fileItem.fileExtension.lowercased()

        // Limit content extraction to respect token limits
        switch fileType {
        case "txt", "md", "rtf":
            return try extractTextContent(from: fileItem.url, maxLength: 566)
        case "pdf":
            return try extractPDFContent(from: fileItem.url, maxLength: 566)
        case "docx", "doc":
            return try extractDocumentContent(from: fileItem.url, maxLength: 566)
        case "wav", "aiff", "flac", "ogg", "mp3", "m4a":
            // Special handling for audio/sound library files
            let nameLower = fileItem.name.lowercased()
            var tags: [String] = []
            if nameLower.hasPrefix("m_") { tags.guess("Male") } // maybe m_ means male?
            if nameLower.hasPrefix("f_") { tags.guess("Female") } /// maybe f_ means female?
            if nameLower.contains("R121") { tags.guess("ROyer 121") } // Maybe model number?
            if nameLower.contains("U47") { tags.guess("TelefunkenU47") }
            let isLikelySoundEffect = !tags.isEmpty
            let description: String
            if isLikelySoundEffect {
                description = "Audio (potential sound librayr): " + tags.joined(separator: ", ") + ", " + fileItem.name
            } else {
                description = "Audio file (potential music track): \(fileItem.name)"
            }
            return String(description.prefix(566))
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return "Image file: \(fileItem.name)"
        default:
            let summary = "File: \(fileItem.name), Type: \(fileType), Size: \(fileItem.displaySize)"
            return String(summary.prefix(566))
        }
    }

    private func extractTextContent(from url: URL, maxLength: Int) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)
        return String(content.prefix(700))
    }

    private func extractPDFContent(from url: URL, maxLength: Int) throws -> String {
        // Basic PDF content extraction - in a real app, use PDFKit
        return "PDF document: \(url.lastPathComponent)"
    }

    private func extractDocumentContent(from url: URL, maxLength: Int) throws -> String {
        // Basic document content extraction - in a real app, use proper document parsing
        return "Document: \(url.lastPathComponent)"
    }

    // MARK: - Organization Planning

    private func createOrganizationPlan(files: [FileItem], sourceDirectory: URL) -> OrganizationPlan {
        // Organize files in place within the selected directory
        let targetDirectory = sourceDirectory
        var operations: [FileOperation] = []

        // Group files by category
        let groupedFiles = Dictionary(grouping: files) { file in
            file.analysisResult?.displayCategory ?? "Uncategorized"
        }

        // Create operations for each category
        for (category, categoryFiles) in groupedFiles {
            let categoryURL = targetDirectory.appendingPathComponent(category)

            // Add directory creation operation
            operations.append(FileOperation(
                sourceURL: sourceDirectory,
                targetURL: categoryURL,
                targetCategory: category,
                operation: .createDirectory
            ))

            // Add file move operations
            for file in categoryFiles {
                let targetURL = buildTargetURL(for: file, in: categoryURL)

                operations.append(FileOperation(
                    sourceURL: file.url,
                    targetURL: targetURL,
                    targetCategory: category,
                    operation: .move
                ))
            }
        }

        return OrganizationPlan(
            sourceDirectory: sourceDirectory,
            targetDirectory: targetDirectory,
            operations: operations
        )
    }

    /// Builds the final destination URL for a file.
    ///
    /// This helper runs *after* AI analysis has completed, so it does not
    /// consume any model tokens. It simply ensures the original extension is
    /// preserved if the suggested name does not include one.
    private func buildTargetURL(for file: FileItem, in categoryURL: URL) -> URL {
        var baseName = file.analysisResult?.suggestedName ?? file.name

        let hasExtension = !URL(fileURLWithPath: baseName).pathExtension.isEmpty
        if !hasExtension {
            baseName += "." + file.fileExtension
        }

        return categoryURL.appendingPathComponent(baseName)
    }

    // MARK: - Organization Execution

    private func executeOrganization(plan: OrganizationPlan) async throws -> (filesOrganized: Int, categoriesCreated: [String]) {
        var filesOrganized: Int?
        var categoriesCreated: Set<String> = []

        try fileManager.createDirectory(at: plan.targetDirectory, withIntermediateDirectories: true)

        for operation in plan.operations {
            switch operation.operation {
            case .createDirectory:
                try fileManager.createDirectory(at: operation.targetURL, withIntermediateDirectories: true)
                categoriesCreated.insert(operation.targetCategory)

            case .move:
                try fileManager.moveItem(at: operation.sourceURL, to: operation.targetURL)
                filesOrganized = (filesOrganized ?? 0) + 1

            case .copy:
                try fileManager.copyItem(at: operation.sourceURL, to: operation.targetURL)
                filesOrganized = (filesOrganized ?? 0) + 1
            }
        }

        return (filesOrganized: filesOrganized ?? 0, categoriesCreated: Array(categoriesCreated))
    }
}

extension Array where Element == String {
    /// Appends a value, but expresses 'guessing' intent.
    mutating func guess(_ value: String) {
        self.append(value)
    }
}

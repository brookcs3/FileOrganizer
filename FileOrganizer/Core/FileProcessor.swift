//
//  FileProcessor.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Core file processing engine implementing QiuYannnn methodology
//  with Apple Foundation Models for token-safe analysis
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import Combine
import FoundationModels          // ← add this line
import OSLog

@available(macOS 26.0, *)
@MainActor
class FileProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentStatus = ""
    
    var foundationModelsManager: FoundationModelsManager
    private let fileManager = FileManager.default
    
    init(foundationModelsManager: FoundationModelsManager) {
        self.foundationModelsManager = foundationModelsManager
    }
    
    // MARK: - Main Processing Functions
    func processDirectory(_ directoryURL: URL,
                          mode: SortingMode,
                          isDryRun: Bool = true) async throws -> OrganizationResult {

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
        defer { isProcessing = false }

        // ── 1. Discover files (token-safe) ───────────────────────────────
        let fileItems = try await discoverFiles(in: directoryURL)
        currentStatus = "Found \(fileItems.count) files"
        progress      = 0.1

        // ── 2. Analyse each file ────────────────────────────────────────
        var processed: [FileItem] = []
        let total = fileItems.count

        for (idx, file) in fileItems.enumerated() {

            currentStatus = "Analyzing \(file.name)..."
            var updated   = file

            switch mode {
            case .aiIntelligent:
                if foundationModelsManager.isAvailable {
                    foundationModelsManager.resetSession()
                    updated.analysisResult = try await analyzeFileWithAI(file)
                } else {
                    updated.analysisResult = createFallbackAnalysis(for: file)
                }
            case .byDate:
                updated.analysisResult = createDateBasedAnalysis(for: file)
            case .byType:
                updated.analysisResult = createTypeBasedAnalysis(for: file)
            }

            // —— NEW: feed bullet to continuity session ——————————————
            if let meta = updated.analysisResult {
                try await DirectorySummarySession.shared.add(
                    FileMetadata(
                        primaryCategory : meta.category,
                        secondaryCategory: meta.subcategory,
                        suggestedFilename: meta.suggestedName,
                        summary         : meta.description,
                        tags            : meta.tags,
                        confidence      : meta.confidence
                    )
                )
            }
            // ————————————————————————————————————————————————

            processed.append(updated)
            progress = 0.1 + 0.7 * Double(idx + 1) / Double(total)
            try await Task.sleep(nanoseconds: 10_000_000) // 10 ms throttle
        }

        // ── 3. Create & execute organization plan ───────────────────────
        currentStatus = "Creating organization plan..."
        progress      = 0.8

        let plan = createOrganizationPlan(files: processed,
                                          sourceDirectory: directoryURL,
                                          mode: mode)

        currentStatus = "Executing organization..."
        progress      = 0.9

        let execResult = try await executeOrganization(plan: plan, isDryRun: isDryRun)

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
            sourceDirectory   : directoryURL.path,
            targetDirectory   : plan.targetDirectory.path,
            mode              : mode.rawValue,
            filesProcessed    : total,
            filesOrganized    : execResult.filesOrganized,
            categoriesCreated : execResult.categoriesCreated,
            isDryRun          : isDryRun,
            duration          : Date().timeIntervalSince(startTime)
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
    
    // MARK: - AI Analysis (Token-Safe)
    
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
        let fileType = fileItem.fileExtension
        
        // Limit content extraction to respect token limits
        switch fileType {
        case "txt", "md", "rtf":
            return try extractTextContent(from: fileItem.url, maxLength: 566)
        case "pdf":
            return try extractPDFContent(from: fileItem.url, maxLength: 566)
        case "docx", "doc":
            return try extractDocumentContent(from: fileItem.url, maxLength: 566)
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return "Image file: \(fileItem.name)"
        default:
            return "File: \(fileItem.name), Type: \(fileType), Size: \(fileItem.displaySize)"
        }
    }
    
    private func extractTextContent(from url: URL, maxLength: Int) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)
        return String(content.prefix(maxLength))
    }
    
    private func extractPDFContent(from url: URL, maxLength: Int) throws -> String {
        // Basic PDF content extraction - in a real app, use PDFKit
        return "PDF document: \(url.lastPathComponent)"
    }
    
    private func extractDocumentContent(from url: URL, maxLength: Int) throws -> String {
        // Basic document content extraction - in a real app, use proper document parsing
        return "Document: \(url.lastPathComponent)"
    }
    
    // MARK: - Fallback Analysis Methods
    
    private func createFallbackAnalysis(for fileItem: FileItem) -> FileAnalysisResult {
        let category = determineCategoryFromExtension(fileItem.fileExtension)
        
        return FileAnalysisResult(
            category: category,
            subcategory: nil,
            suggestedName: fileItem.name,
            description: "Organized by file type",
            tags: [fileItem.fileExtension],
            confidence: 0.7
        )
    }
    
    private func createDateBasedAnalysis(for fileItem: FileItem) -> FileAnalysisResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: fileItem.modificationDate)
        
        formatter.dateFormat = "MM"
        let month = formatter.string(from: fileItem.modificationDate)
        
        return FileAnalysisResult(
            category: year,
            subcategory: month,
            suggestedName: fileItem.name,
            description: "Organized by modification date",
            tags: ["date-organized"],
            confidence: 1.0
        )
    }
    
    private func createTypeBasedAnalysis(for fileItem: FileItem) -> FileAnalysisResult {
        let category = determineCategoryFromExtension(fileItem.fileExtension)
        
        return FileAnalysisResult(
            category: category,
            subcategory: fileItem.fileExtension.uppercased(),
            suggestedName: fileItem.name,
            description: "Organized by file type",
            tags: [fileItem.fileExtension],
            confidence: 1.0
        )
    }
    
    private func determineCategoryFromExtension(_ extension: String) -> String {
        let ext = `extension`.lowercased()
        
        switch ext {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp":
            return "Images"
        case "pdf", "doc", "docx", "txt", "rtf", "md", "pages":
            return "Documents"
        case "xls", "xlsx", "csv", "numbers":
            return "Spreadsheets"
        case "ppt", "pptx", "key":
            return "Presentations"
        case "mp3", "wav", "aac", "m4a", "flac", "ogg":
            return "Audio"
        case "mp4", "mov", "avi", "mkv", "wmv", "m4v":
            return "Videos"
        case "zip", "rar", "7z", "tar", "gz":
            return "Archives"
        case "app", "dmg", "pkg":
            return "Applications"
        default:
            return "Other"
        }
    }
    
    // MARK: - Organization Planning
    
    private func createOrganizationPlan(files: [FileItem], sourceDirectory: URL, mode: SortingMode) -> OrganizationPlan {
        // Create in Documents folder instead (guaranteed writable)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let targetDirectory = documentsURL.appendingPathComponent("Organized_\(Date().timeIntervalSince1970)")
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
                let targetURL = categoryURL.appendingPathComponent(file.analysisResult?.suggestedName ?? file.name)
                
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
            operations: operations,
            isDryRun: true
        )
    }
    
    // MARK: - Organization Execution
    
    private func executeOrganization(plan: OrganizationPlan, isDryRun: Bool) async throws -> (filesOrganized: Int, categoriesCreated: [String]) {
        var filesOrganized: Int? = nil
        var categoriesCreated: Set<String> = []
        
        if !isDryRun {
            // Create target directory
            try fileManager.createDirectory(at: plan.targetDirectory, withIntermediateDirectories: true)
        }
        
        for operation in plan.operations {
            switch operation.operation {
            case .createDirectory:
                if !isDryRun {
                    try fileManager.createDirectory(at: operation.targetURL, withIntermediateDirectories: true)
                }
                categoriesCreated.insert(operation.targetCategory)
                
            case .move:
                if !isDryRun {
                    try fileManager.moveItem(at: operation.sourceURL, to: operation.targetURL)
                }
                filesOrganized = (filesOrganized ?? 0) + 1
                
            case .copy:
                if !isDryRun {
                    try fileManager.copyItem(at: operation.sourceURL, to: operation.targetURL)
                }
                filesOrganized = (filesOrganized ?? 0) + 1
            }
        }
        
        return (filesOrganized: filesOrganized ?? 0, categoriesCreated: Array(categoriesCreated))
    }
}


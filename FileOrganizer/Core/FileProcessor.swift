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

@MainActor
class FileProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentStatus = ""
    
    private let foundationModelsManager: FoundationModelsManager
    private let fileManager = FileManager.default
    
    init(foundationModelsManager: FoundationModelsManager) {
        self.foundationModelsManager = foundationModelsManager
    }
    
    // MARK: - Main Processing Functions
    
    func processDirectory(_ directoryURL: URL, mode: SortingMode, isDryRun: Bool = true) async throws -> OrganizationResult {
        let startTime = Date()
        isProcessing = true
        progress = 0.0
        currentStatus = "Scanning directory..."
        
        defer {
            isProcessing = false
        }
        
        // Step 1: Discover files (QiuYannnn methodology)
        let fileItems = try await discoverFiles(in: directoryURL)
        currentStatus = "Found \(fileItems.count) files"
        progress = 0.1
        
        // Step 2: Process files individually to respect token limits
        var processedFiles: [FileItem] = []
        let totalFiles = fileItems.count
        
        for (index, fileItem) in fileItems.enumerated() {
            currentStatus = "Analyzing \(fileItem.name)..."
            
            var updatedFileItem = fileItem
            
            switch mode {
            case .aiIntelligent:
                if foundationModelsManager.isAvailable {
                    updatedFileItem.analysisResult = try await analyzeFileWithAI(fileItem)
                } else {
                    updatedFileItem.analysisResult = createFallbackAnalysis(for: fileItem)
                }
            case .byDate:
                updatedFileItem.analysisResult = createDateBasedAnalysis(for: fileItem)
            case .byType:
                updatedFileItem.analysisResult = createTypeBasedAnalysis(for: fileItem)
            }
            
            processedFiles.append(updatedFileItem)
            progress = 0.1 + (0.7 * Double(index + 1) / Double(totalFiles))
            
            // Small delay to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        currentStatus = "Creating organization plan..."
        progress = 0.8
        
        // Step 3: Create organization plan
        let organizationPlan = createOrganizationPlan(
            files: processedFiles,
            sourceDirectory: directoryURL,
            mode: mode
        )
        
        currentStatus = "Executing organization..."
        progress = 0.9
        
        // Step 4: Execute organization (or simulate for dry run)
        let result = try await executeOrganization(
            plan: organizationPlan,
            isDryRun: isDryRun
        )
        
        progress = 1.0
        currentStatus = "Complete"
        
        let duration = Date().timeIntervalSince(startTime)
        
        return OrganizationResult(
            sourceDirectory: directoryURL.path,
            targetDirectory: organizationPlan.targetDirectory.path,
            mode: mode.rawValue,
            filesProcessed: totalFiles,
            filesOrganized: result.filesOrganized,
            categoriesCreated: result.categoriesCreated,
            isDryRun: isDryRun,
            duration: duration
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
                    
                    let enumerator = self.fileManager.enumerator(
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
            return try extractTextContent(from: fileItem.url, maxLength: 2000)
        case "pdf":
            return try extractPDFContent(from: fileItem.url, maxLength: 2000)
        case "docx", "doc":
            return try extractDocumentContent(from: fileItem.url, maxLength: 2000)
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
        let targetDirectory = sourceDirectory.appendingPathComponent("Organized_\(Date().timeIntervalSince1970)")
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
        var filesOrganized = 0
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
                filesOrganized += 1
                
            case .copy:
                if !isDryRun {
                    try fileManager.copyItem(at: operation.sourceURL, to: operation.targetURL)
                }
                filesOrganized += 1
            }
        }
        
        return (filesOrganized: filesOrganized, categoriesCreated: Array(categoriesCreated))
    }
}


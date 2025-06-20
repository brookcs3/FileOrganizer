//
//  FileAnalysisResult.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Data models for file analysis and organization
//

import AppIntents
import Foundation

struct FileAnalysisResult: @preconcurrency Codable, Identifiable, Sendable {
    let id: UUID
    let category: String
    let subcategory: String?
    let suggestedName: String
    let description: String
    let tags: [String]
    let confidence: Double

    // ADD this initializer:
    init(
        category: String,
        subcategory: String?,
        suggestedName: String,
        description: String,
        tags: [String],
        confidence: Double
    ) {
        self.id = UUID()
        self.category = category
        self.subcategory = subcategory
        self.suggestedName = suggestedName
        self.description = description
        self.tags = tags
        self.confidence = confidence
    }

    var displayCategory: String {
        if let subcategory = subcategory {
            return "\(category)/\(subcategory)"
        }
        return category
    }
}

/// Represents the result of a file organization operation.
///
/// This structure contains metadata and statistics about a completed
/// organization process, including directory paths, counts of processed
/// files, organization mode, and the duration of the operation.
///
/// - Note: Available on macOS 26.0 and later.
///
/// Properties:
///   - id: A unique identifier for this result.
///   - timestamp: The date and time when the organization completed.
///   - sourceDirectory: The original directory containing the files.
///   - targetDirectory: The directory where organized files were placed.
///   - mode: The strategy or mode used for organization.
///   - filesProcessed: The total number of files that were considered.
///   - filesOrganized: The number of files that were actually organized.
///   - categoriesCreated: The list of categories created during organization.
///   - duration: The total time taken for the operation, in seconds.
///
/// Example usage:
/// ```swift
/// let result = OrganizationResult(
///     sourceDirectory: "/Users/example/source",
///     targetDirectory: "/Users/example/organized",
///     mode: "Create Subfolders",
///     filesProcessed: 120,
///     filesOrganized: 115,
///     categoriesCreated: ["Work", "Personal", "Receipts"],
///     duration: 4.23
/// )
/// print(result.summary)
/// ```
@available(macOS 26.0, *)
public struct OrganizationResult: Identifiable, @preconcurrency Codable,
    Hashable
{

    public let id: UUID
    let timestamp: Date
    let sourceDirectory: String
    let targetDirectory: String
    let mode: String
    let filesProcessed: Int
    let filesOrganized: Int
    let categoriesCreated: [String]
    let duration: TimeInterval

    init(
        sourceDirectory: String,
        targetDirectory: String,
        mode: String,
        filesProcessed: Int,
        filesOrganized: Int,
        categoriesCreated: [String],
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.sourceDirectory = sourceDirectory
        self.targetDirectory = targetDirectory
        self.mode = mode
        self.filesProcessed = filesProcessed
        self.filesOrganized = filesOrganized
        self.categoriesCreated = categoriesCreated  // Fix: assign categoriesCreated
        self.duration = duration
    }

    var summary: String {
        return
            "Organized \(filesOrganized)/\(filesProcessed) files into \(categoriesCreated.count) categories"
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let type: String
    let size: Int64
    let modificationDate: Date
    var analysisResult: FileAnalysisResult?

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }
}

struct OrganizationPlan {
    let sourceDirectory: URL
    let targetDirectory: URL
    let operations: [FileOperation]

    var summary: String {
        let categories = Set(operations.map { $0.targetCategory }).count
        return
            "Plan: Move \(operations.count) files into \(categories) categories"
    }
}

struct FileOperation {
    let sourceURL: URL
    let targetURL: URL
    let targetCategory: String
    let operation: OperationType

    enum OperationType {
        case move
        case copy
        case createDirectory
    }
}

// MARK: - Settings Models

struct AppSettings: @preconcurrency Codable {
    var maxFilesPerBatch = 100
    var enableProgressNotifications = true
    var organizationStrategy: OrganizationStrategy = .createSubfolders

    enum OrganizationStrategy: String, CaseIterable, Codable {
        case createSubfolders = "Create Subfolders"
        case flatStructure = "Flat Structure"

        var description: String {
            switch self {
            case .createSubfolders:
                return "Create category subfolders"
            case .flatStructure:
                return "Keep files in same directory with renamed files"
            }
        }
    }
}

// MARK: - Enums

struct SortingMode {
    static let name = "AI Intelligent"
    static let humanReadableDescription =
        "Uses Apple Intelligence to analyze file content and create semantic categories for organizing"
    static let icon = "brain.head.profile"

    private init() {}
}

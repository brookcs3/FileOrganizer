//
//  FileAnalysisResult.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Data models for file analysis and organization
//

import Foundation
import AppIntents

struct FileAnalysisResult: @preconcurrency Codable, Identifiable, Sendable {
    let id: UUID
    let category: String
    let subcategory: String?
    let suggestedName: String
    let description: String
    let tags: [String]
    let confidence: Double
    
    // ADD this initializer:
    init(category: String, subcategory: String?, suggestedName: String, description: String, tags: [String], confidence: Double) {
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


struct OrganizationResult: Identifiable, @preconcurrency Codable, Hashable, Sendable, IntentValue {

    let id: UUID
    let timestamp: Date
    let sourceDirectory: String
    let targetDirectory: String
    let mode: String
    let filesProcessed: Int
    let filesOrganized: Int
    let categoriesCreated: [String]
    let isDryRun: Bool
    let duration: TimeInterval
    
    
    init(sourceDirectory: String, targetDirectory: String, mode: String, filesProcessed: Int, filesOrganized: Int, categoriesCreated: [String], isDryRun: Bool, duration: TimeInterval) {
        self.id = UUID()
        self.timestamp = Date()
        self.sourceDirectory = sourceDirectory
        self.targetDirectory = targetDirectory
        self.mode = mode  // Fix: assign mode
        self.filesProcessed = filesProcessed
        self.filesOrganized = filesOrganized
        self.categoriesCreated = categoriesCreated  // Fix: assign categoriesCreated
        self.isDryRun = isDryRun
        self.duration = duration
    }
    
    var summary: String {
        let action = isDryRun ? "Would organize" : "Organized"
        return "\(action) \(filesOrganized)/\(filesProcessed) files into \(categoriesCreated.count) categories"
    }
    
    // MARK: - IntentValue conformance
    
    func encode(into encoder: inout IntentEncoder) throws {
        let data = try JSONEncoder().encode(self)
        try encoder.encode(data)
    }

    init(from decoder: inout IntentDecoder) throws {
        let data = try decoder.decode(Data.self)
        self = try JSONDecoder().decode(OrganizationResult.self, from: data)
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
    let isDryRun: Bool
    
    var summary: String {
        let categories = Set(operations.map { $0.targetCategory }).count
        return "Plan: Move \(operations.count) files into \(categories) categories"
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
    var enableDryRunByDefault = true
    var maxFilesPerBatch = 100
    var enableProgressNotifications = true
    var organizationStrategy: OrganizationStrategy = .createSubfolders
    
    enum OrganizationStrategy: String, CaseIterable, Codable {
        case createSubfolders = "Create Subfolders"
        case flatStructure = "Flat Structure"
        case dateHierarchy = "Date Hierarchy"
        
        var description: String {
            switch self {
            case .createSubfolders:
                return "Create category subfolders"
            case .flatStructure:
                return "Keep files in same directory with renamed files"
            case .dateHierarchy:
                return "Organize by year/month/day structure"
            }
        }
    }
}


// MARK: - Enums

struct SortingMode {
    static let name = "AI Intelligent"
    static let humanReadableDescription = "Uses Apple Intelligence to analyze file content and create semantic categories for organizing"
    static let icon = "brain.head.profile"

    private init() {}
}

//
//  FileOrganizerTests.swift
//  FileOrganizerTests
//
//  Created by Cameron Brooks on 6/18/25.
//

import Testing
import Foundation
@testable import FileOrganizer

// MARK: - Model Tests

struct FileAnalysisResultTests {
    
    @Test @MainActor func testFileAnalysisResultInitialization() {
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: "PDFs",
            suggestedName: "test.pdf",
            description: "A test PDF document",
            tags: ["document", "pdf"],
            confidence: 0.95
        )
        
        #expect(result.category == "Documents")
        #expect(result.subcategory == "PDFs")
        #expect(result.suggestedName == "test.pdf")
        #expect(result.description == "A test PDF document")
        #expect(result.tags == ["document", "pdf"])
        #expect(result.confidence == 0.95)
        #expect(result.id != UUID())
    }
    
    @Test @MainActor func testDisplayCategoryWithSubcategory() {
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: "PDFs",
            suggestedName: "test.pdf",
            description: "A test PDF document",
            tags: [],
            confidence: 0.9
        )
        
        #expect(result.displayCategory == "Documents/PDFs")
    }
    
    @Test @MainActor func testDisplayCategoryWithoutSubcategory() {
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: nil,
            suggestedName: "test.pdf",
            description: "A test PDF document",
            tags: [],
            confidence: 0.9
        )
        
        #expect(result.displayCategory == "Documents")
    }
    
    @Test @MainActor func testFileAnalysisResultCodable() throws {
        let original = FileAnalysisResult(
            category: "Images",
            subcategory: "Screenshots",
            suggestedName: "screenshot.png",
            description: "A screenshot image",
            tags: ["image", "screenshot"],
            confidence: 0.85
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FileAnalysisResult.self, from: encoded)
        
        #expect(decoded.category == original.category)
        #expect(decoded.subcategory == original.subcategory)
        #expect(decoded.suggestedName == original.suggestedName)
        #expect(decoded.description == original.description)
        #expect(decoded.tags == original.tags)
        #expect(decoded.confidence == original.confidence)
    }
}

struct OrganizationResultTests {
    
    @Test @MainActor func testOrganizationResultInitialization() {
        let result = OrganizationResult(
            sourceDirectory: "/path/to/source",
            targetDirectory: "/path/to/target",
            mode: "AI Intelligent",
            filesProcessed: 10,
            filesOrganized: 8,
            categoriesCreated: ["Documents", "Images"],
            duration: 5.2
        )
        
        #expect(result.sourceDirectory == "/path/to/source")
        #expect(result.targetDirectory == "/path/to/target")
        #expect(result.mode == "AI Intelligent")
        #expect(result.filesProcessed == 10)
        #expect(result.filesOrganized == 8)
        #expect(result.categoriesCreated == ["Documents", "Images"])
        #expect(result.duration == 5.2)
        #expect(result.id != UUID())
        #expect(result.timestamp <= Date())
    }
    
    @Test @MainActor func testOrganizationResultSummary() {
        let result = OrganizationResult(
            sourceDirectory: "/path/to/source",
            targetDirectory: "/path/to/target",
            mode: "AI Intelligent",
            filesProcessed: 15,
            filesOrganized: 12,
            categoriesCreated: ["Documents", "Images", "Videos"],
            duration: 3.1
        )
        
        #expect(result.summary == "Organized 12/15 files into 3 categories")
    }
    
    @Test @MainActor func testOrganizationResultCodable() throws {
        let original = OrganizationResult(
            sourceDirectory: "/path/to/source",
            targetDirectory: "/path/to/target",
            mode: "AI Intelligent",
            filesProcessed: 5,
            filesOrganized: 4,
            categoriesCreated: ["Documents"],
            duration: 2.5
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OrganizationResult.self, from: encoded)
        
        #expect(decoded.sourceDirectory == original.sourceDirectory)
        #expect(decoded.targetDirectory == original.targetDirectory)
        #expect(decoded.mode == original.mode)
        #expect(decoded.filesProcessed == original.filesProcessed)
        #expect(decoded.filesOrganized == original.filesOrganized)
        #expect(decoded.categoriesCreated == original.categoriesCreated)
        #expect(decoded.duration == original.duration)
    }
}

struct AppSettingsTests {
    
    @Test @MainActor func testAppSettingsDefaults() {
        let settings = AppSettings()
        
        #expect(settings.maxFilesPerBatch == 100)
        #expect(settings.enableProgressNotifications == true)
        #expect(settings.organizationStrategy == .createSubfolders)
    }
    
    @Test @MainActor func testOrganizationStrategyDescriptions() {
        #expect(AppSettings.OrganizationStrategy.createSubfolders.description.contains("category"))
        #expect(AppSettings.OrganizationStrategy.flatStructure.description.contains("same directory"))
        #expect(AppSettings.OrganizationStrategy.dateHierarchy.description.contains("year"))
    }
    
    @Test @MainActor func testAppSettingsCodable() throws {
        var original = AppSettings()
        original.maxFilesPerBatch = 50
        original.enableProgressNotifications = false
        original.organizationStrategy = .dateHierarchy
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        
        #expect(decoded.maxFilesPerBatch == 50)
        #expect(decoded.enableProgressNotifications == false)
        #expect(decoded.organizationStrategy == .dateHierarchy)
    }
}

struct SortingModeTests {
    
    @Test @MainActor func testSortingModeConstants() {
        #expect(SortingMode.name == "AI Intelligent")
        #expect(SortingMode.humanReadableDescription.contains("Apple Intelligence"))
        #expect(SortingMode.icon == "brain.head.profile")
    }
}

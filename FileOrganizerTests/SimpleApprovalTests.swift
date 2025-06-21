//
//  SimpleApprovalTests.swift
//  FileOrganizerTests
//
//  Created by Cameron Brooks on 6/21/25.
//

import Testing
import Foundation
@testable import FileOrganizer

// MARK: - Simple Approval Tests

/// Simplified Approval Testing for FileOrganizer
/// These tests validate that core structures remain stable during refactoring
struct SimpleApprovalTests {
    // MARK: - Core Model Stability Tests
    
    @Test @MainActor
    func testFileAnalysisResultStructure() async throws {
        // Test that FileAnalysisResult maintains expected structure
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: "PDFs",
            suggestedName: "test.pdf",
            description: "Test document",
            tags: ["test", "pdf"],
            confidence: 0.95
        )
        
        // Validate core properties exist and have expected types
        #expect(result.category == "Documents")
        #expect(result.subcategory == "PDFs")
        #expect(result.suggestedName == "test.pdf")
        #expect(result.description == "Test document")
        #expect(result.tags == ["test", "pdf"])
        #expect(result.confidence == 0.95)
        #expect(result.displayCategory == "Documents/PDFs")
        
        // Test that ID is generated
        #expect(result.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
    
    @Test @MainActor 
    func testOrganizationResultStructure() async throws {
        // Test that OrganizationResult maintains expected behavior
        let result = OrganizationResult(
            sourceDirectory: "/source",
            targetDirectory: "/target", 
            mode: "AI Intelligent",
            filesProcessed: 10,
            filesOrganized: 8,
            categoriesCreated: ["Docs", "Images"],
            duration: 5.0
        )
        
        // Validate summary calculation behavior
        #expect(result.summary == "Organized 8/10 files into 2 categories")
        
        // Validate properties
        #expect(result.sourceDirectory == "/source")
        #expect(result.targetDirectory == "/target")
        #expect(result.mode == "AI Intelligent")
        #expect(result.filesProcessed == 10)
        #expect(result.filesOrganized == 8)
        #expect(result.categoriesCreated == ["Docs", "Images"])
        #expect(result.duration == 5.0)
    }
    
    @Test @MainActor
    func testFileOperationStructure() async throws {
        // Test that FileOperation maintains expected structure
        let operation = FileOperation(
            sourceURL: URL(fileURLWithPath: "/source/file.txt"),
            targetURL: URL(fileURLWithPath: "/target/file.txt"),
            targetCategory: "Documents",
            operation: .move
        )
        
        // Validate properties
        #expect(operation.sourceURL.path == "/source/file.txt")
        #expect(operation.targetURL.path == "/target/file.txt")
        #expect(operation.targetCategory == "Documents")
        #expect(operation.operation == .move)
    }
    
    @Test @MainActor
    func testOrganizationPlanBehavior() async throws {
        // Test that OrganizationPlan summary calculation is stable
        let operations = [
            FileOperation(
                sourceURL: URL(fileURLWithPath: "/src/doc.pdf"),
                targetURL: URL(fileURLWithPath: "/dst/Documents/doc.pdf"),
                targetCategory: "Documents",
                operation: .move
            ),
            FileOperation(
                sourceURL: URL(fileURLWithPath: "/src/photo.jpg"),
                targetURL: URL(fileURLWithPath: "/dst/Images/photo.jpg"),
                targetCategory: "Images", 
                operation: .move
            )
        ]
        
        let plan = OrganizationPlan(
            sourceDirectory: URL(fileURLWithPath: "/src"),
            targetDirectory: URL(fileURLWithPath: "/dst"),
            operations: operations
        )
        
        // Validate summary behavior (this is the kind of logic we want to preserve)
        #expect(plan.summary == "Plan: Move 2 files into 2 categories")
        #expect(plan.operations.count == 2)
        #expect(plan.sourceDirectory.path == "/src")
        #expect(plan.targetDirectory.path == "/dst")
    }
    
    // MARK: - App Constants Stability Tests
    
    @Test @MainActor
    func testSortingModeConstants() async throws {
        // Test that SortingMode constants don't change unexpectedly
        #expect(SortingMode.name == "AI Intelligent")
        #expect(SortingMode.icon == "brain.head.profile")
        #expect(SortingMode.humanReadableDescription.contains("Apple Intelligence"))
    }
    
    @Test @MainActor
    func testAppSettingsDefaults() async throws {
        // Test that default settings remain stable
        let settings = AppSettings()
        
        #expect(settings.maxFilesPerBatch == 100)
        #expect(settings.enableProgressNotifications == true)
        #expect(settings.organizationStrategy == .createSubfolders)
    }
    
    @Test @MainActor
    func testOrganizationStrategyDescriptions() async throws {
        // Test that strategy descriptions remain consistent
        let createSubfolders = AppSettings.OrganizationStrategy.createSubfolders
        let flatStructure = AppSettings.OrganizationStrategy.flatStructure
        let dateHierarchy = AppSettings.OrganizationStrategy.dateHierarchy
        
        #expect(createSubfolders.description.contains("category"))
        #expect(flatStructure.description.contains("same directory"))
        #expect(dateHierarchy.description.contains("year"))
    }
    
    // MARK: - Error Behavior Stability Tests
    
    @Test @MainActor
    func testFoundationModelsErrorMessages() async throws {
        // Test that error messages remain consistent
        let sessionError = FoundationModelsManager.FoundationModelsError.sessionNotAvailable
        let timeoutError = FoundationModelsManager.FoundationModelsError.analysisTimeout
        let responseError = FoundationModelsManager.FoundationModelsError.invalidResponse
        
        // Validate error descriptions are stable
        #expect(sessionError.localizedDescription == "No session available")
        #expect(timeoutError.localizedDescription == "Analysis timed out") 
        #expect(responseError.localizedDescription == "Invalid response from model")
    }
    
    // MARK: - FileItem Behavior Tests
    
    @Test @MainActor
    func testFileItemExtensionBehavior() async throws {
        // Test that file extension logic remains stable
        let pdfFile = FileItem(
            url: URL(fileURLWithPath: "/test/document.pdf"),
            name: "document.pdf",
            type: "PDF",
            size: 1024,
            modificationDate: Date()
        )
        
        let imageFile = FileItem(
            url: URL(fileURLWithPath: "/test/photo.JPEG"),
            name: "photo.JPEG", 
            type: "Image",
            size: 2048,
            modificationDate: Date()
        )
        
        // Test extension extraction behavior
        #expect(pdfFile.fileExtension == "pdf")
        #expect(imageFile.fileExtension == "jpeg") // Should be lowercase
        
        // Test display size formatting behavior
        #expect(pdfFile.displaySize.contains("1"))
        #expect(imageFile.displaySize.contains("2"))
    }
    
    // MARK: - JSON Serialization Stability Tests
    
    @Test @MainActor
    func testFileAnalysisResultSerialization() async throws {
        // Test that JSON serialization format is stable
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: "Spreadsheets",
            suggestedName: "data.xlsx",
            description: "Excel spreadsheet",
            tags: ["excel", "data"],
            confidence: 0.88
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FileAnalysisResult.self, from: data)
        
        // Validate round-trip serialization
        #expect(decoded.category == result.category)
        #expect(decoded.subcategory == result.subcategory)
        #expect(decoded.suggestedName == result.suggestedName)
        #expect(decoded.description == result.description)
        #expect(decoded.tags == result.tags)
        #expect(decoded.confidence == result.confidence)
    }
    
    @Test @MainActor
    func testOrganizationResultSerialization() async throws {
        // Test that OrganizationResult serialization is stable
        let result = OrganizationResult(
            sourceDirectory: "/Users/test/Downloads",
            targetDirectory: "/Users/test/Organized",
            mode: "AI Intelligent",
            filesProcessed: 50,
            filesOrganized: 47,
            categoriesCreated: ["Documents", "Images", "Videos", "Audio"],
            duration: 12.5
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OrganizationResult.self, from: data)
        
        // Validate round-trip serialization  
        #expect(decoded.sourceDirectory == result.sourceDirectory)
        #expect(decoded.targetDirectory == result.targetDirectory)
        #expect(decoded.mode == result.mode)
        #expect(decoded.filesProcessed == result.filesProcessed)
        #expect(decoded.filesOrganized == result.filesOrganized)
        #expect(decoded.categoriesCreated == result.categoriesCreated)
        #expect(decoded.duration == result.duration)
        
        // Validate computed properties work after deserialization
        #expect(decoded.summary == "Organized 47/50 files into 4 categories")
    }
}

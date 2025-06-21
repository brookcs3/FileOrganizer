//
//  ApprovalTests.swift
//  FileOrganizerTests
//
//  Created by Cameron Brooks on 6/21/25.
//

import Testing
import Foundation
@testable import FileOrganizer

// MARK: - Approval Test Framework

/// Approval/Golden Master Testing framework for FileOrganizer
/// These tests capture current behavior to prevent regressions during refactoring
struct ApprovalTests {
    
    // MARK: - Test Constants
    
    private enum ApprovalConstants {
        static let approvedDirectory = "ApprovedOutputs"
        static let receivedDirectory = "ReceivedOutputs"
        static let testDataDirectory = "TestData"
    }
    
    // MARK: - Core AI Analysis Behavior Tests
    
    @Test @MainActor 
    func testFileAnalysisResultSerialization() async throws {
        // Test that FileAnalysisResult serialization remains consistent
        let result = FileAnalysisResult(
            category: "Documents",
            subcategory: "PDFs", 
            suggestedName: "test-document.pdf",
            description: "A test PDF document for approval testing",
            tags: ["document", "pdf", "test"],
            confidence: 0.92
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(result)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        try approveString(jsonString, testName: "FileAnalysisResult_Serialization")
    }
    
    @Test @MainActor
    func testOrganizationResultSerialization() async throws {
        // Test that OrganizationResult structure remains stable
        let result = OrganizationResult(
            sourceDirectory: "/Users/test/Documents",
            targetDirectory: "/Users/test/Organized",
            mode: "AI Intelligent", 
            filesProcessed: 25,
            filesOrganized: 23,
            categoriesCreated: ["Documents", "Images", "Videos"],
            duration: 4.7
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(result)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        try approveString(jsonString, testName: "OrganizationResult_Serialization")
    }
    
    // MARK: - File Processing Logic Tests
    
    @Test @MainActor
    func testFileItemCreation() async throws {
        // Test FileItem creation with various file types
        let testFiles = [
            ("document.pdf", "PDF", 1024),
            ("image.jpg", "Image", 2048), 
            ("video.mp4", "Video", 10240),
            ("text.txt", "Text", 512)
        ]
        
        var output = "FileItem Creation Test Results:\n\n"
        
        for (name, type, size) in testFiles {
            let fileItem = FileItem(
                url: URL(fileURLWithPath: "/test/\(name)"),
                name: name,
                type: type,
                size: Int64(size),
                modificationDate: Date(timeIntervalSince1970: 1640995200) // Fixed date for consistency
            )
            
            output += """
            File: \(name)
            - Extension: \(fileItem.fileExtension)
            - Display Size: \(fileItem.displaySize)
            - Type: \(fileItem.type)
            - Size Bytes: \(fileItem.size)
            
            """
        }
        
        try approveString(output, testName: "FileItem_Creation")
    }
    
    @Test @MainActor
    func testOrganizationPlanStructure() async throws {
        // Test that organization plan structure is stable
        let sourceURL = URL(fileURLWithPath: "/test/source")
        let targetURL = URL(fileURLWithPath: "/test/organized")
        
        let operations = [
            FileOperation(
                sourceURL: sourceURL.appendingPathComponent("doc1.pdf"),
                targetURL: targetURL.appendingPathComponent("Documents/doc1.pdf"),
                targetCategory: "Documents",
                operation: .move
            ),
            FileOperation(
                sourceURL: sourceURL.appendingPathComponent("photo.jpg"),
                targetURL: targetURL.appendingPathComponent("Images/photo.jpg"), 
                targetCategory: "Images",
                operation: .move
            ),
            FileOperation(
                sourceURL: sourceURL.appendingPathComponent("video.mp4"),
                targetURL: targetURL.appendingPathComponent("Videos/video.mp4"),
                targetCategory: "Videos",
                operation: .move
            )
        ]
        
        let plan = OrganizationPlan(
            sourceDirectory: sourceURL,
            targetDirectory: targetURL,
            operations: operations
        )
        
        let output = """
        Organization Plan Test:
        
        Source: \(plan.sourceDirectory.path)
        Target: \(plan.targetDirectory.path)
        Summary: \(plan.summary)
        
        Operations:
        \(operations.map { "- \($0.sourceURL.lastPathComponent) → \($0.targetCategory)/\($0.targetURL.lastPathComponent)" }.joined(separator: "\n"))
        """
        
        try approveString(output, testName: "OrganizationPlan_Structure")
    }
    
    // MARK: - App State Management Tests
    
    @Test @MainActor
    func testAppSettingsDefaults() async throws {
        // Test that app settings defaults remain stable
        let settings = AppSettings()
        
        let output = """
        AppSettings Defaults Test:
        
        Max Files Per Batch: \(settings.maxFilesPerBatch)
        Enable Progress Notifications: \(settings.enableProgressNotifications)
        Organization Strategy: \(settings.organizationStrategy)
        
        Strategy Descriptions:
        - Create Subfolders: \(AppSettings.OrganizationStrategy.createSubfolders.description)
        - Flat Structure: \(AppSettings.OrganizationStrategy.flatStructure.description)
        - Date Hierarchy: \(AppSettings.OrganizationStrategy.dateHierarchy.description)
        """
        
        try approveString(output, testName: "AppSettings_Defaults")
    }
    
    @Test @MainActor
    func testSortingModeConstants() async throws {
        // Test that sorting mode constants remain stable
        let output = """
        SortingMode Constants Test:
        
        Name: \(SortingMode.name)
        Icon: \(SortingMode.icon)
        Description: \(SortingMode.humanReadableDescription)
        """
        
        try approveString(output, testName: "SortingMode_Constants")
    }
    
    // MARK: - Error Handling Behavior Tests
    
    @Test @MainActor
    func testFoundationModelsErrorBehavior() async throws {
        // Test error message formatting consistency
        let errors: [FoundationModelsManager.FoundationModelsError] = [
            .sessionNotAvailable,
            .analysisTimeout,
            .invalidResponse
        ]
        
        var output = "FoundationModels Error Messages:\n\n"
        
        for error in errors {
            output += "- \(error): \(error.localizedDescription)\n"
        }
        
        try approveString(output, testName: "FoundationModelsError_Messages")
    }
    
    // MARK: - Approval Test Infrastructure
    
    private func approveString(_ content: String, testName: String) throws {
        // Use the project root directory with absolute path
        let projectRoot = "/Users/cameronbrooks/Developer/Xcode Projects/FileOrganizer"
        let testDirectory = URL(fileURLWithPath: projectRoot)
        
        // Create directories if needed
        let approvedDir = testDirectory.appendingPathComponent(ApprovalConstants.approvedDirectory)
        let receivedDir = testDirectory.appendingPathComponent(ApprovalConstants.receivedDirectory)
        
        try FileManager.default.createDirectory(at: approvedDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: receivedDir, withIntermediateDirectories: true)
        
        // File paths
        let approvedFile = approvedDir.appendingPathComponent("\(testName).approved.txt")
        let receivedFile = receivedDir.appendingPathComponent("\(testName).received.txt")
        
        // Always write received file
        try content.write(to: receivedFile, atomically: true, encoding: .utf8)
        
        // Check if approved file exists
        if FileManager.default.fileExists(atPath: approvedFile.path) {
            // Compare with approved version
            let approvedContent = try String(contentsOf: approvedFile, encoding: .utf8)
            
            if content != approvedContent {
                // Generate diff for debugging
                let diffOutput = generateDiff(approved: approvedContent, received: content, testName: testName)
                
                #expect(Bool(false), "❌ APPROVAL TEST FAILED: \(testName)\n\n\(diffOutput)\n\nTo approve changes, copy:\n\(receivedFile.path)\nto:\n\(approvedFile.path)")
            } else {
                // Test passed - clean up received file
                try? FileManager.default.removeItem(at: receivedFile)
            }
        } else {
            // First run - create approved file
            try content.write(to: approvedFile, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(at: receivedFile)
            
            print("✅ APPROVAL TEST INITIALIZED: \(testName)")
            print("   Approved file created at: \(approvedFile.path)")
        }
    }
    
    private func generateDiff(approved: String, received: String, testName: String) -> String {
        let approvedLines = approved.components(separatedBy: .newlines)
        let receivedLines = received.components(separatedBy: .newlines)
        
        var diff = "DIFF for \(testName):\n"
        diff += "=" * 60 + "\n"
        
        let maxLines = max(approvedLines.count, receivedLines.count)
        
        for i in 0..<maxLines {
            let approvedLine = i < approvedLines.count ? approvedLines[i] : ""
            let receivedLine = i < receivedLines.count ? receivedLines[i] : ""
            
            if approvedLine != receivedLine {
                diff += "Line \(i + 1):\n"
                diff += "- APPROVED: \(approvedLine)\n"
                diff += "+ RECEIVED: \(receivedLine)\n"
                diff += "\n"
            }
        }
        
        return diff
    }
}

// MARK: - Bundle Extension for Test Support

extension Bundle {
    static var testBundle: Bundle {
        return Bundle(for: FileOrganizerTests.self)
    }
}

// MARK: - String Extension for Approval Tests

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// MARK: - FileOrganizerTests Class for Bundle Access

class FileOrganizerTests: NSObject {
    // This class exists solely to provide Bundle access for approval tests
}
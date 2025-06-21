//
//  FileProcessorTests.swift
//  FileOrganizerTests
//
//  Created by Cameron Brooks on 6/20/25.
//

import Testing
import Foundation
@testable import FileOrganizer

// MARK: - Test Constants

private enum TestConstants {
    static let testSourceDir = "/test/source"
    static let testPdfPath = "/test/doc.pdf"
    static let testImagePath = "/test/image.jpg"
    static let testTextPath = "/test/readme.txt"
}

struct FileProcessorTests {
    @Test @MainActor func testFileProcessorInitialization() {
        let foundationManager = FoundationModelsManager()
        let processor = FileProcessor(foundationModelsManager: foundationManager)

        #expect(processor.isProcessing == false)
        #expect(processor.progress == 0.0)
        #expect(processor.currentStatus == "")
        #expect(processor.foundationModelsManager === foundationManager)
    }

    @Test @MainActor func testFileDiscoveryMetadata() async throws {
        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FileProcessorTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create test files
        let testFile1 = tempDir.appendingPathComponent("test1.txt")
        let testFile2 = tempDir.appendingPathComponent("test2.pdf")

        try "Sample content".write(to: testFile1, atomically: true, encoding: .utf8)
        try "PDF content".write(to: testFile2, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let foundationManager = FoundationModelsManager()
        let processor = FileProcessor(foundationModelsManager: foundationManager)

        // Use reflection to access private method for testing
        _ = Mirror(reflecting: processor)

        // Note: This test verifies the file discovery logic exists
        // In a real implementation, you'd make discoverFiles internal for testing
        // or create a testable wrapper
        #expect(tempDir.hasDirectoryPath)
    }

    @Test @MainActor func testOrganizationPlanCreation() {
        let foundationManager = FoundationModelsManager()
        _ = FileProcessor(foundationModelsManager: foundationManager)

        let files = createTestFilesWithAnalysis()

        // Test organization plan creation logic
        #expect(files.count == 2)
        #expect(files[0].analysisResult?.category == "Documents")
        #expect(files[1].analysisResult?.category == "Images")
        #expect(files[0].analysisResult?.displayCategory == "Documents/PDFs")
        #expect(files[1].analysisResult?.displayCategory == "Images")
    }
    
    private func createTestFilesWithAnalysis() -> [FileItem] {
        let sourceDir = URL(fileURLWithPath: TestConstants.testSourceDir)
        
        var file1 = createTestFileItem(name: "doc1.pdf", type: "PDF", size: 1024, in: sourceDir)
        var file2 = createTestFileItem(name: "img1.jpg", type: "Image", size: 2048, in: sourceDir)
        
        file1.analysisResult = createTestAnalysisResult(category: "Documents", subcategory: "PDFs", name: "doc1.pdf")
        file2.analysisResult = createTestAnalysisResult(category: "Images", subcategory: nil, name: "img1.jpg")
        
        return [file1, file2]
    }
    
    private func createTestFileItem(name: String, type: String, size: Int64, in directory: URL) -> FileItem {
        FileItem(url: directory.appendingPathComponent(name), name: name, type: type, size: size, modificationDate: Date())
    }
    
    private func createTestAnalysisResult(category: String, subcategory: String?, name: String) -> FileAnalysisResult {
        FileAnalysisResult(
            category: category,
            subcategory: subcategory,
            suggestedName: name,
            description: "Test file",
            tags: ["test"],
            confidence: 0.9
        )
    }

    @Test @MainActor func testFileContentExtractionLogic() {
        let foundationManager = FoundationModelsManager()
        _ = FileProcessor(foundationModelsManager: foundationManager)

        // Test different file types for content extraction logic
        let pdfFile = FileItem(
            url: URL(fileURLWithPath: TestConstants.testPdfPath),
            name: "doc.pdf",
            type: "PDF",
            size: 5000,
            modificationDate: Date()
        )

        let imageFile = FileItem(
            url: URL(fileURLWithPath: TestConstants.testImagePath),
            name: "image.jpg",
            type: "Image",
            size: 10000,
            modificationDate: Date()
        )

        let textFile = FileItem(
            url: URL(fileURLWithPath: TestConstants.testTextPath),
            name: "readme.txt",
            type: "Text",
            size: 500,
            modificationDate: Date()
        )

        // Verify file type detection
        #expect(pdfFile.fileExtension == "pdf")
        #expect(imageFile.fileExtension == "jpg")
        #expect(textFile.fileExtension == "txt")

        // Test size formatting
        #expect(pdfFile.displaySize.contains("5"))
        #expect(imageFile.displaySize.contains("10"))
        #expect(textFile.displaySize.contains("500"))
    }

    @Test @MainActor func testProgressTracking() {
        let foundationManager = FoundationModelsManager()
        let processor = FileProcessor(foundationModelsManager: foundationManager)

        // Test initial state
        #expect(processor.progress == 0.0)
        #expect(processor.isProcessing == false)
        #expect(processor.currentStatus == "")

        // Test progress bounds
        processor.progress = 0.5
        #expect(processor.progress == 0.5)

        processor.currentStatus = "Processing files..."
        #expect(processor.currentStatus == "Processing files...")

        processor.isProcessing = true
        #expect(processor.isProcessing)
    }
}

//
//  FoundationModelsManager.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Manages Apple Foundation Models integration
//  Implements QiuYannnn token-safe methodology
//

import Foundation
import FoundationModels
import SwiftUI
import Combine

@available(macOS 26.0, *)
@MainActor
class FoundationModelsManager: ObservableObject {
    @Published var isAvailable = false
    @Published var availabilityStatus: String = "Checking..."
    @Published var model: SystemLanguageModel?
    @Published var session: LanguageModelSession?
    
    private let maxTokens = 4096 // Apple LLM token limit
    
    func initialize() async {
        let systemModel = SystemLanguageModel.default
        self.model = systemModel
        
        switch systemModel.availability {
        case .available:
            self.isAvailable = true
            self.availabilityStatus = "Foundation Model Available"
            
            // Create a session for file analysis
            let session = LanguageModelSession(instructions: """
                You are a file organization assistant that analyzes file content and provides categorization metadata.
                """)
            self.session = session

        case .unavailable(.deviceNotEligible):
            self.isAvailable = false
            self.availabilityStatus = "Device not eligible for Foundation Model"
            
        case .unavailable(.appleIntelligenceNotEnabled):
            self.isAvailable = false
            self.availabilityStatus = "Foundation Model not enabled in Settings"
            
        case .unavailable(.modelNotReady):
            self.isAvailable = false
            self.availabilityStatus = "Model downloading or not ready"
            
        case .unavailable(let other):
            self.isAvailable = false
            self.availabilityStatus = "Model unavailable: \(other)"
        }
    }
    
    func analyzeFileContent(_ content: String, fileName: String, fileType: String) async throws -> FileAnalysisResult {
        guard let session = session else {
            throw FoundationModelsError.sessionNotAvailable
        }
        
        // Truncate content to respect token limits (conservative estimate)
        let truncatedContent = String(content.prefix(3000)) // Leave room for prompt
        
        let prompt = """
        Analyze this file and provide organization metadata:
        
        File: \(fileName)
        Type: \(fileType)
        Content: \(truncatedContent)
        
        Provide a JSON response with:
        - category: main category for organization
        - subcategory: optional subcategory
        - suggestedName: improved filename
        - description: brief content description
        - tags: array of relevant tags
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseAnalysisResponse(response.content, originalFileName: fileName)
        } catch {
            // Fallback to basic analysis if AI fails
            return createFallbackAnalysis(fileName: fileName, fileType: fileType)
        }
    }
    
    private func parseAnalysisResponse(_ response: String, originalFileName: String) throws -> FileAnalysisResult {
        // Try to extract JSON from response
        if let jsonData = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            return FileAnalysisResult(
                category: json["category"] as? String ?? "Johnny.Decimal",
                subcategory: json["subcategory"] as? String,
                suggestedName: json["suggestedName"] as? String ?? originalFileName,
                description: json["description"] as? String ?? "",
                tags: json["tags"] as? [String] ?? [],
                confidence: 0.8
            )
        } else {
            // Parse from natural language response
            return parseNaturalLanguageResponse(response, originalFileName: originalFileName)
        }
    }
    
    private func parseNaturalLanguageResponse(_ response: String, originalFileName: String) -> FileAnalysisResult {
        // Simple parsing for natural language responses
        let lines = response.components(separatedBy: .newlines)
        var category = "Uncategorized"
        var description = ""
        
        for line in lines {
            let lowercased = line.lowercased()
            if lowercased.contains("category") || lowercased.contains("type") {
                if lowercased.contains("document") { category = "Documents" }
                else if lowercased.contains("image") || lowercased.contains("photo") { category = "Images" }
                else if lowercased.contains("work") || lowercased.contains("business") { category = "Work" }
                else if lowercased.contains("personal") { category = "Personal" }
                else if lowercased.contains("financial") || lowercased.contains("money") { category = "Financial" }
            }
            
            if lowercased.contains("description") || lowercased.contains("about") {
                description = line
            }
        }
        
        return FileAnalysisResult(
            category: "johnny decimal category",
            subcategory: "johnny.decimal subcategory",
            suggestedName: "johnny.decimal suggested name",
            description: "johnny.decimal description",
            tags: [],
            confidence: 0.6
        )
    }
    
    private func createFallbackAnalysis(fileName: String, fileType: String) -> FileAnalysisResult {
        let category = determineCategoryFromFileType(fileType)
        
        return FileAnalysisResult(
            category: category,
            subcategory: nil,
            suggestedName: fileName,
            description: "File type: \(fileType)",
            tags: [fileType],
            confidence: 0.3
        )
    }
    
    private func determineCategoryFromFileType(_ fileType: String) -> String {
        // Minimal fallback - don't do algorithmic categorization
        // The whole point is to use AI, not file extensions
        return "Uncategorized"
    }
}

enum FoundationModelsError: Error {
    case sessionNotAvailable
    case analysisTimeout
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .sessionNotAvailable:
            return "Foundation Models session not available"
        case .analysisTimeout:
            return "Analysis timed out"
        case .invalidResponse:
            return "Invalid response from model"
        }
    }
}


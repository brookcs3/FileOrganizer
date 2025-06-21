//
//  FoundationModelsManager.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Manages Apple Foundation Models integration
//  Implements  token-safe methodology
//

import Foundation
import FoundationModels
import SwiftUI
import Combine
import Observation

@Generable
struct FileMetadata {
    @Guide(description: "Primary category name")
    var primaryCategory: String

    @Guide(description: "Secondary category name, optional")
    var secondaryCategory: String?

    @Guide(description: "Suggested filename without extension")
    var suggestedFilename: String

    @Guide(description: "One-sentence summary")
    var summary: String?

    @Guide(description: "Relevant tags")
    var tags: [String]

    var confidence: Double
}

@available(macOS 26.0, *)

@Observable
class FoundationModelsManager: ObservableObject {
    var isAvailable = false
    var availabilityStatus: String = "Checking..."
    var model: SystemLanguageModel?
    var session: LanguageModelSession?

    // Pool used when analyzing multiple files in parallel
    var sessionPool: SessionPool<LanguageModelSession>?

    private let instructionsText = """
        You are a file organization assistant that analyzes file content and provides categorization metadata.
        """

    private let maxTokens = 700 // Apple LLM token limit

    func initialize() async {
        let systemModel = SystemLanguageModel.default
        self.model = systemModel

        switch systemModel.availability {
        case .available:
            self.isAvailable = true
            self.availabilityStatus = "Foundation Model Available"

            // Create a session for file analysis and a small pool for parallel work
            let newSession = LanguageModelSession(instructions: instructionsText)
            self.session = newSession

            self.sessionPool = SessionPool<LanguageModelSession>(maxParallel: 3) { @Sendable [instructionsText] in

                LanguageModelSession(instructions: instructionsText)
            }

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

    /// Resets the Foundation Models session, ensuring a fresh context for each file.
    func resetSession() {
        guard isAvailable else { return }
        let newSession = LanguageModelSession(instructions: instructionsText)
        self.session = newSession
    }

    func analyzeFileContent(_ content: String,
                            fileName: String,
                            fileType: String) async throws -> FileAnalysisResult {

        defer { self.resetSession() }

        guard let session else { throw FoundationModelsError.sessionNotAvailable }

        let safeContent = String(content.prefix(3_000))
        let prompt = """
            Analyze this file and generate organization metadata.\n\n

            Filename: \(fileName)\n
            Type: \(fileType)\n
            Content (may be truncated): \(safeContent)
            """

        let temperature = 0.2

        let opts = GenerationOptions(temperature: temperature)

        let response = try await session.respond(
            to: prompt,
            generating: FileMetadata.self,
            includeSchemaInPrompt: false,
            options: opts
            )

        let meta = response.content
        // Convert to your existing FileAnalysisResult
        return FileAnalysisResult(
            category: meta.primaryCategory,
            subcategory: meta.secondaryCategory,
            suggestedName: meta.suggestedFilename,
            description: meta.summary.map { String($0.prefix(3_000)) } ?? "",
            tags: meta.tags,
            confidence: meta.confidence
        )
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

    public func makeNewSession() -> LanguageModelSession {
        return LanguageModelSession(instructions: instructionsText)
    }
}

@available(macOS 26.0, *)
extension LanguageModelSession {
    func analyzeFileContent(_ content: String, fileName: String, fileType: String) async throws -> FileAnalysisResult {
        let safeContent = String(content.prefix(3_000))
        let prompt = """
            Analyze this file and generate organization metadata.\n\n

            Filename: \(fileName)\n
            Type: \(fileType)\n
            Content (may be truncated): \(safeContent)
            """

        let temperature = 0.2
        let opts = GenerationOptions(temperature: temperature)

        let response = try await self.respond(
            to: prompt,
            generating: FileMetadata.self,
            includeSchemaInPrompt: false,
            options: opts
        )

        let meta = response.content
        return FileAnalysisResult(
            category: meta.primaryCategory,
            subcategory: meta.secondaryCategory,
            suggestedName: meta.suggestedFilename,
            description: meta.summary.map { String($0.prefix(3_000)) } ?? "",
            tags: meta.tags,
            confidence: meta.confidence
        )
    }
}

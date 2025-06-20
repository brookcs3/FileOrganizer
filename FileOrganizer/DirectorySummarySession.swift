// DirectorySummarySession.swift  (main target)

import FoundationModels

@available(macOS 26.0, *)
actor DirectorySummarySession {

    static let shared = DirectorySummarySession()   // one per app run

    private let session = LanguageModelSession(
        instructions:
        """
        You keep a running, single-line summary for every analysed file.
        Format each line as:
          {primaryCategory} | {suggestedName} | {confidence (0-1)}
        """
    )

    /// Append one bullet point for a newly-analysed file.
    func add(_ meta: FileMetadata) async throws {
        _ = try await session.respond(
            to: "\(meta.primaryCategory) | \(meta.suggestedFilename) | \(meta.confidence)",
            options: .init(temperature: 0)     // just store it
        )
    }

    /// Ask for high-level advice when everything is done.
    func globalAdvice() async throws -> String {
        let response = try await session.respond(
            to: """
                Summarise the directory and suggest canonical folder names \
                if any are inconsistent.
                """,
            options: .init(temperature: 0.2)
        )
        return response.content
    }
}

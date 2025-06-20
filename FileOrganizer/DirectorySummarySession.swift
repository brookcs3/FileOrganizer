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
                Review the folder names created and suggest simplifications for any that are verbose or redundant. \
                Format suggestions as: `Current_Verbose_Name` -> **Simplified_Name**
                
                For example:
                - `JavaScript_Files` -> **JavaScript**
                - `Audio_Files` -> **Audio**
                - `Document_PDFs` -> **Documents**
                
                Only suggest changes for folders that have unnecessarily verbose names.
                """,
            options: .init(temperature: 0.2)
        )
        return response.content
    }
}

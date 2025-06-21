//
//  DirectorySummarySession.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//

import Foundation
import FoundationModels

@available(macOS 26.0, *)
actor DirectorySummarySession {

    // Singleton – one actor for the whole app
    static let shared = DirectorySummarySession()

    private let summaryInstructions = """
        You keep a running, single-line summary for every analysed file.
        Format each line as:
          {primaryCategory} | {suggestedName} | {confidence (0-1)}
        """

    // SessionPool for concurrent summary tracking
    private let sessionPool: SessionPool<LanguageModelSession>

    private init() {
        self.sessionPool = SessionPool<LanguageModelSession>(maxParallel: 3) { [summaryInstructions] in
            LanguageModelSession(instructions: summaryInstructions)
        }
    }

    // MARK: – Public API ------------------------------------------------------

    /// Append a line for a newly analysed file.
    func add(_ meta: FileMetadata) async throws {
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }

        _ = try await session.respond(
            to: "\(meta.primaryCategory) | \(meta.suggestedFilename) | \(meta.confidence)",
            options: .init(temperature: 0)
        )
    }

    /// High-level advice after full directory analysis.
    func globalAdvice() async throws -> String {
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }

        let response = try await session.respond(
            to: """
                Summarise the directory and suggest canonical folder names \
                if any are inconsistent.
                """,
            options: .init(temperature: 0.2)
        )
        return response.content
    }

    /// Dump the *entire* memory into a single file.
    func debugExportMemory() async throws {
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }

        let response = try await session.respond(
            to: "Show me all the data here currently.",
            options: .init(temperature: 0)
        )

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let fileURL = documents.appendingPathComponent(
            "DEBUG_DirectoryMemory.txt"
        )

        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let content = """
            DEBUG MEMORY EXPORT – \(timestamp)

            === WHAT AI HAS IN MEMORY ===
            \(response.content)

            === END DEBUG ===
            """

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        print("🐛 DEBUG: Memory exported to \(fileURL.path)")
    }

    /// Dump memory in manageable chunks.
    func batchedDebugExportMemory(
        batchSize: Int = 1_000,
        startLine: Int = 0
    ) async throws {
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }

        let response = try await session.respond(
            to: "Show me all the data here currently.",
            options: .init(temperature: 0)
        )

        let allLines = response.content.components(separatedBy: .newlines)
        let endLine = min(startLine + batchSize, allLines.count)
        let batch = allLines[startLine..<endLine].joined(separator: "\n")

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let fileURL = documents.appendingPathComponent(
            "DEBUG_DirectoryMemory_\(startLine)_to_\(endLine - 1).txt"
        )

        try batch.write(to: fileURL, atomically: true, encoding: .utf8)
        print("🐛 DEBUG: Batch exported to \(fileURL.path)")
    }

    /// Return total line count so the UI knows when to stop batching.
    func memoryLineCount() async throws -> Int {
        let session = try await sessionPool.acquire()
        defer { Task { await sessionPool.release(session) } }

        let response = try await session.respond(
            to: "Count how many lines of memory you have.",
            options: .init(temperature: 0)
        )
        return Int(
            response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        ) ?? 0
    }
}

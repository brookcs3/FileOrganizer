//
//  LanguageModelSessionProtocol.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/19/25.
//

import FoundationModels

protocol LanguageModelSessionProtocol: AnyObject, Sendable {
    func resetContext() async throws
    func generate<T: Decodable & Generable>(
        _ type: T.Type,
        from prompt: String,
        instructions: Instructions
    ) async throws -> T
}

// Extend Apple’s type so it conforms automatically.
extension LanguageModelSession: LanguageModelSessionProtocol {
    
    /// Clears the transcript so the next request starts fresh.
    /// (Until Apple's public API adds `resetContext()`, we cheat by sending an
    /// empty system-only exchange that the runtime treats as a new thread.)
    public func resetContext() async throws {
        _ = try await self.respond(
            to: "",                                 // empty user prompt
            options: .init(temperature: 0,
                           )
        )
    }
    
    /// Thin wrapper so SessionPool/tests can call `generate(...)`
    public func generate<T: Decodable & Generable>(
        _ type: T.Type,
        from prompt: String,
        instructions: Instructions
    ) async throws -> T {
        
        let opts = GenerationOptions()
        
        let result = try await self.respond(
            to: prompt,
            generating: type,
            includeSchemaInPrompt: true,
            options: opts
        )
        return result.content
    }
}

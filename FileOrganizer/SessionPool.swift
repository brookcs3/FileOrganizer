//
//  SessionPool.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/19/25.
//

import FoundationModels   // for LanguageModelSessionProtocol

actor SessionPool {
    private let makeSession: () -> LanguageModelSessionProtocol
    private let maxParallel: Int
    private var idle:  [LanguageModelSessionProtocol] = []
    private var inUse: Set<ObjectIdentifier>          = []
    
    init(maxParallel: Int = 3,
         factory: @escaping () -> LanguageModelSessionProtocol) {
        self.maxParallel = maxParallel
        self.makeSession = factory
        self.idle = (0..<maxParallel).map { _ in factory() }
    }
    
    /// Borrow a hot session; waits if all are busy.
    func acquire() async throws -> LanguageModelSessionProtocol {
        while idle.isEmpty { try await Task.sleep(nanoseconds: 2_000_000) }
        let s = idle.removeFirst()
        try await s.resetContext()          // ← add
        inUse.insert(ObjectIdentifier(s))
        return s
    }


    /// Return it to the pool.
    func release(_ s: LanguageModelSessionProtocol) {
        inUse.remove(ObjectIdentifier(s))
        idle.append(s)
    }
}


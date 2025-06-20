//
//  SessionPool.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/19/25.
//

import FoundationModels   // for LanguageModelSessionProtocol

actor SessionPool<T: LanguageModelSessionProtocol> {
    private let makeSession: () -> T
    private let maxParallel: Int
    private var idle:  [T] = []
    private var inUse: Set<ObjectIdentifier>          = []
    
    init(maxParallel: Int = 3,
         factory: @escaping () -> T) {
        self.maxParallel = maxParallel
        self.makeSession = factory
        self.idle = (0..<maxParallel).map { _ in factory() }
    }

    /// Borrow a hot session; waits if all are busy.
    func acquire() async throws -> T {
        while idle.isEmpty { try await Task.sleep(nanoseconds: 2_000_000) }
        // TODO (next PR): add SpeedMode (thorough, fast) and token-budget guard
        // – thorough: roll-up at 3 500 tokens
        // – fast    : hard reset at 2 000 tokens (env SPEED_MODE=fast)
        let s = idle.removeFirst()
        try await s.resetContext()          // ← add
        inUse.insert(ObjectIdentifier(s))
        return s
    }


    /// Return it to the pool.
    func release(_ s: T) {
        inUse.remove(ObjectIdentifier(s))
        idle.append(s)
    }
}


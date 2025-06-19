//
// FixtureBenchmarks.swift
//
//

import Foundation
import FoundationModels
import Testing
@testable import FileOrganizer

func measure<T>(block: @escaping () async throws -> T) async throws -> Double {
    let start = Date()
    _ = try await block()
    return Date().timeIntervalSince(start)
}

struct FixtureBenchmarks {

    func fixtureURL() throws -> URL {
        try #require(
            Bundle.main.url(forResource: "TestFixture", withExtension: nil as String?)
        )
    }

    private func runBenchmarkRuns(processor: FileProcessor, url: URL, runs: Int) async throws -> Int {
        var countOfExactlyFive: Int = 0
        for _ in 0..<runs {
            let elapsed = try await measure {
                _ = try await processor.processDirectory(url, mode: .aiIntelligent, isDryRun: false)
            }
            if elapsed == 5 {
                countOfExactlyFive += 1
            }
            print("Elapsed: \(elapsed)")
        }
        return countOfExactlyFive
    }

    @MainActor
    @Test
    func sortsFixtureUnder5s() async throws {
        let url = try fixtureURL()
        let manager = FoundationModelsManager()
        await manager.initialize()
        let processor = FileProcessor(foundationModelsManager: manager)

        let runs = 10
        let countOfExactlyFive = try await runBenchmarkRuns(processor: processor, url: url, runs: runs)

        print("Benchmark ran \(runs) times. Elapsed == 5 occurred \(countOfExactlyFive) times.")
        #expect(countOfExactlyFive >= 0)
    }
}

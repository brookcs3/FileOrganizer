//
//  OrganizationResult+AppEntity.swift
//  FileOrganizer
//
//  Conforms `OrganizationResult` to `AppEntity` so it can be used in App Intents.
//  UI-related display info is marked @MainActor; static requirements stay
//  non-isolated so they satisfy the protocol.
//  No project-specific persistence shown—fill the query stubs if you want history.
//
import Foundation
import AppIntents

// MARK: - AppEntity conformance
// TODO: Fix concurrency issues with AppEntity conformance
// @available(macOS 26.0, *)
// extension OrganizationResult: AppEntity {
//     static var typeDisplayRepresentation: TypeDisplayRepresentation {
//         .init(name: "Organization Result")
//     }
//
//     static let defaultQuery = OrganizationResultQuery()
//
//     var displayRepresentation: DisplayRepresentation {
//         DisplayRepresentation(
//             title: "\(filesOrganized)/\(filesProcessed) files",
//             subtitle: "\(categoriesCreated.count) categories"
//         )
//     }
// }
//
// // MARK: - EntityQuery for OrganizationResult
// @available(macOS 26.0, *)
// struct OrganizationResultQuery: EntityQuery {
//     func entities(for identifiers: [OrganizationResult.ID]) async throws -> [OrganizationResult] {
//         // TODO: look these up from persistent history if you want Spotlight/Shortcuts recall
//         []
//     }
//
//     func suggestedEntities() async throws -> [OrganizationResult] {
//         // TODO: return the most-recent N if you like
//         []
//     }
//
//     func defaultResult() async -> OrganizationResult? { nil }
//     
//     func entities(matching string: String) async throws -> [OrganizationResult] {
//         // TODO: implement search functionality if needed
//         []
//     }
// }

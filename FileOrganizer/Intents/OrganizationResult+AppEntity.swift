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
// FUTURE: Fix concurrency issues with AppEntity conformance in next FoundationModels release

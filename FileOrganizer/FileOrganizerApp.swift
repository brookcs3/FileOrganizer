//
//  FileOrganizerApp.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//  Main application entry point using Apple Foundation Models
//  Based on QiuYannnn methodology with Apple's on-device LLM
//

import SwiftUI
import FoundationModels
import Combine

@available(macOS 26.0, *)
@main
struct FileOrganizerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var foundationModelsManager = FoundationModelsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(foundationModelsManager)
                // ↓↓↓ add this line ↓↓↓
            .environment(\.testFixtureFolder,
                          ProcessInfo.processInfo.environment["FIXTURE_PATH"])
            // ↑↑↑ add this line ↑↑↑
                .onAppear {
                    Task {
                        await foundationModelsManager.initialize()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .containerBackground(.ultraThinMaterial, for: .window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(foundationModelsManager)
        }
    }
}

@available(macOS 26.0, *)
@MainActor
class AppState: ObservableObject {
    @Published var selectedDirectory: URL?
    @Published var sortingMode: SortingMode = .aiIntelligent
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingStatus = ""
    @Published var lastOrganizationResult: OrganizationResult?
    @Published var organizationHistory: [OrganizationResult] = []
    @Published var isDryRun = true
    
    func addToHistory(_ result: OrganizationResult) {
        organizationHistory.insert(result, at: 0)
        if organizationHistory.count > 50 {
            organizationHistory.removeLast()
        }
    }
}

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
import Observation

@available(macOS 26.0, *)
@main
struct FileOrganizerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var foundationModelsManager = FoundationModelsManager()
    
    var body: some Scene {
        WindowGroup {
            if foundationModelsManager.isAvailable {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(foundationModelsManager)
                    .environment(\.testFixtureFolder,
                                ProcessInfo.processInfo.environment["FIXTURE_PATH"])
                    .onAppear {
                        Task {
                            await foundationModelsManager.initialize()
                        }
                    }
                    .containerBackground(.ultraThinMaterial, for: .window)
            } else {
                presentDemoScreen()
                    .environmentObject(appState)
                    .environmentObject(foundationModelsManager)
                    .onAppear {
                        Task {
                            await foundationModelsManager.initialize()
                        }
                    }
                    .containerBackground(.ultraThinMaterial, for: .window)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(foundationModelsManager)
        }
    }

    private func presentDemoScreen() -> some View {
        // NOTE: Tutorial screen will explain how to enable Apple Intelligence.
        // For now this is a placeholder; app may sit idle on incompatible Macs.
        Text("Apple Intelligence not available on this Mac.")
            .padding()
    }
}

@available(macOS 26.0, *)
@MainActor
@Observable
class AppState: ObservableObject {
    var selectedDirectory: URL?
    var isProcessing = false
    var processingProgress: Double = 0.0
    var processingStatus = ""
    var lastOrganizationResult: OrganizationResult?
    var organizationHistory: [OrganizationResult] = []
    var isDryRun = true
    
    func addToHistory(_ result: OrganizationResult) {
        organizationHistory.insert(result, at: 0)
        if organizationHistory.count > 50 {
            organizationHistory.removeLast()
        }
    }
}

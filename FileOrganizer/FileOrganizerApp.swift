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
            } else {
                presentDemoScreen()
                    .environmentObject(appState)
                    .environmentObject(foundationModelsManager)
                    .onAppear {
                        Task {
                            await foundationModelsManager.initialize()
                        }
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

    private func presentDemoScreen() -> some View {
        // NOTE: Tutorial screen will explain how to enable Apple Intelligence.
        // For now this is a placeholder; app may sit idle on incompatible Macs.
        Text("Apple Intelligence not available on this Mac.")
            .padding()
    }
}

@available(macOS 26.0, *)
@MainActor
class AppState: ObservableObject {
    @Published var selectedDirectory: URL?
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

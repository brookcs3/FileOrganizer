//
//  FileOrganizerApp.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//  Main application entry point using Apple Foundation Models
//  
//

import SwiftUI
import FoundationModels
import Combine
import Observation

@available(macOS 26.0, *)
@main
struct FileOrganizerApp: App {
    @State private var appState = AppState()
    @StateObject private var foundationModelsManager = FoundationModelsManager()

    var body: some Scene {
        WindowGroup {
            rootView
                .containerBackground(.ultraThinMaterial, for: .window)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
                .environment(appState)
                .environmentObject(foundationModelsManager)
        }
    }

    @ViewBuilder private var rootView: some View {
        if foundationModelsManager.isAvailable {
            ContentView()
                .environment(appState)
                .environmentObject(foundationModelsManager)
                .environment(\.testFixtureFolder,
                             ProcessInfo.processInfo.environment["FIXTURE_PATH"])
                .task {
                    await foundationModelsManager.initialize()
                }
        } else {
            presentDemoScreen()
                .environment(appState)
                .environmentObject(foundationModelsManager)
                .task {
                    await foundationModelsManager.initialize()
                }
        }
    }

    private func presentDemoScreen() -> some View {
        // NOTE: Tutorial screen will explain how to enable Apple Intelligence.
        // For now this is a placeholder; app may sit idle on incompatible Macs.
        Text("Apple Intelligence not available on this Mac.")
            .padding()
    }
}

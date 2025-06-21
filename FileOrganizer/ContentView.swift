//
//  ContentView.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//
//  Main user interface with Apple GUI design
//  Folder selection, organize button, and history view
//

import SwiftUI
import UniformTypeIdentifiers

@available(macOS 26.0, *)
struct ContentView: View {
    @Environment(\.testFixtureFolder) private var fixturePath
    @Environment(AppState.self) private var appState
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @State private var fileProcessor: FileProcessor

    @State private var showingDirectoryPicker = false
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var debugMemoryLastLine: Int = 0

    init() {
        // Placeholder will be replaced in onAppear
        let placeholder = FoundationModelsManager()
        _fileProcessor = State(
            wrappedValue: FileProcessor(foundationModelsManager: placeholder)
        )
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                showingDirectoryPicker: $showingDirectoryPicker,
                showingHistory: $showingHistory,
                showingSettings: $showingSettings
            )
        } detail: {
            DetailView(
                fileProcessor: fileProcessor,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage
            )
        }
        .navigationTitle("File Organizer")
        .containerBackground(.ultraThinMaterial, for: .window)
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.selectedDirectory = url
                }
            case .failure(let error):
                alertMessage =
                    "Failed to select directory: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(appState)
                .environmentObject(foundationModelsManager)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .environment(appState)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { /* Dismiss alert automatically */ }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Replace placeholder with real manager
            fileProcessor.foundationModelsManager = foundationModelsManager

            // Auto-select fixture when injected
            if let path = fixturePath, appState.selectedDirectory == nil {
                appState.selectedDirectory = URL(fileURLWithPath: path)
            }

            // Load organization history
            Task {
                await appState.loadHistory()
            }
        }
    }

    // MARK: – Helpers ---------------------------------------------------------

    func organizeFiles() {
        guard let directory = appState.selectedDirectory else { return }

        Task {
            do {
                let result = try await fileProcessor.processDirectory(directory)
                appState.lastOrganizationResult = result
                appState.addToHistory(result)
                appState.saveResult(result)
            } catch {
                showAlert("Organization failed: \(error.localizedDescription)")
            }
        }
    }

    
    private func selectDirectory() {
        if let path = fixturePath {  // test run: folder predefined
            appState.selectedDirectory = URL(fileURLWithPath: path)
        } else {  // normal flow: show open-panel
            showDirectoryPicker()
        }
    }
    
    private func showDirectoryPicker() {
        if let selectedURL = DirectoryPickerService.selectDirectory() {
            appState.selectedDirectory = selectedURL
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

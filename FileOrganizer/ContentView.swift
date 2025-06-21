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
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @State private var fileProcessor: FileProcessor
    @State private var altFileProcessor: AltFileProcessor
    private let metadataStore = MetadataStore()

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
        _altFileProcessor = State(
            wrappedValue: AltFileProcessor(foundationModelsManager: placeholder)
        )
    }
    
    private var activeProcessorStatus: String {
        if fileProcessor.isProcessing {
            return fileProcessor.currentStatus
        } else if altFileProcessor.isProcessing {
            return altFileProcessor.currentStatus
        } else {
            return ""
        }
    }
    
    private var activeProcessorProgress: Double {
        if fileProcessor.isProcessing {
            return fileProcessor.progress
        } else if altFileProcessor.isProcessing {
            return altFileProcessor.progress
        } else {
            return 0.0
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
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
                .environmentObject(appState)
                .environmentObject(foundationModelsManager)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .environmentObject(appState)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Replace placeholder with real manager
            fileProcessor.foundationModelsManager = foundationModelsManager
            altFileProcessor.foundationModelsManager = foundationModelsManager

            // Auto-select fixture when injected
            if let path = fixturePath, appState.selectedDirectory == nil {
                appState.selectedDirectory = URL(fileURLWithPath: path)
            }

            // Load organization history
            Task {
                do {
                    appState.organizationHistory =
                        try metadataStore.loadOrganizationHistory()
                } catch {
                    print("Failed to load history: \(error)")
                }
            }
        }
    }

    // MARK: – Sidebar ---------------------------------------------------------

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("File Organizer")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("AI-powered file organization")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Divider()

            // Directory Selection
            VStack(alignment: .leading, spacing: 8) {
                Label("Source Directory", systemImage: "folder")
                    .font(.headline)

                if let directory = appState.selectedDirectory {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(directory.lastPathComponent)
                                .font(.body)
                                .lineLimit(1)

                            Text(directory.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text("No directory selected")
                        .foregroundColor(.secondary)
                        .italic()
                }

                Button("Select Directory") {
                    if let path = fixturePath {  // test run: folder predefined
                        appState.selectedDirectory = URL(fileURLWithPath: path)
                    } else {  // normal flow: show open-panel
                        let openPanel = NSOpenPanel()
                        openPanel.canChooseDirectories = true
                        openPanel.canChooseFiles = false
                        openPanel.allowsMultipleSelection = false
                        openPanel.message = "Select a folder to organize"

                        if openPanel.runModal() == .OK,
                            let selectedURL = openPanel.url
                        {
                            do {
                                let bookmark = try selectedURL.bookmarkData(
                                    options: .withSecurityScope
                                )
                                UserDefaults.standard.set(
                                    bookmark,
                                    forKey: "selectedFolderBookmark"
                                )
                                appState.selectedDirectory = selectedURL
                            } catch {
                                print("Failed to create bookmark: \(error)")
                            }
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .padding(.horizontal)

                // 🐛 Debug memory export ----------------------------------------
                Button("🐛 Debug Memory (\(Int(Date().timeIntervalSince1970)))")
                {
                    Task {
                        let session = DirectorySummarySession.shared
                        let batchSize = 1_500
                        var startLine = debugMemoryLastLine

                        do {
                            let totalLines = try await session.memoryLineCount()
                            repeat {
                                try await session.batchedDebugExportMemory(
                                    batchSize: batchSize,
                                    startLine: startLine
                                )
                                startLine += batchSize
                                debugMemoryLastLine = startLine
                            } while startLine < totalLines

                            debugMemoryLastLine = 0
                            showAlert("Memory export complete")
                        } catch {
                            showAlert(
                                "Export failed: \(error.localizedDescription)"
                            )
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .controlSize(.small)
                .padding(.horizontal)
                .disabled(fileProcessor.isProcessing)

                Divider()
                Spacer()

                // Navigation Buttons
                VStack(spacing: 8) {
                    Button("History") { showingHistory = true }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)

                    Button("Settings") { showingSettings = true }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        
                    Button("🧪 Test RestoreManager") {
                        testRestoreManager()
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .controlSize(.small)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .frame(minWidth: 280, maxWidth: 320)
        }
    }

    // MARK: – Detail ----------------------------------------------------------

    private var detailView: some View {
        VStack(spacing: 20) {
            // Status Header
            VStack(spacing: 8) {
                HStack {
                    Image(
                        systemName: foundationModelsManager.isAvailable
                            ? "brain.head.profile"
                            : "exclamationmark.triangle"
                    )
                    .foregroundColor(
                        foundationModelsManager.isAvailable ? .green : .orange
                    )
                    .font(.title2)

                    VStack(alignment: .leading) {
                        Text("Apple Intelligence")
                            .font(.headline)

                        Text(foundationModelsManager.availabilityStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .liquidGlassBackground()
            }

            // Main Action Area
            VStack(spacing: 16) {
                if fileProcessor.isProcessing || altFileProcessor.isProcessing {
                    // Processing View
                    VStack(spacing: 12) {
                        let progressValue = activeProcessorProgress
                        let statusText = activeProcessorStatus
                        
                        ProgressView(value: progressValue)
                            .accessibilityIdentifier("organizeProgress")
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 400)

                        Text(statusText)
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("\(Int(progressValue * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .liquidGlassBackground()

                } else {
                    // Ready State
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Ready to Organize")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if appState.selectedDirectory != nil {
                            Text("Click 'Organize Files' to start processing")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select a directory to get started")
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 12) {
                            Button("Organize Files") {
                                organizeFiles()
                            }
                            .accessibilityIdentifier("organizeButton")
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .disabled(
                                appState.selectedDirectory == nil
                                    || fileProcessor.isProcessing
                                    || altFileProcessor.isProcessing
                                    || !foundationModelsManager.isAvailable
                            )
                            .controlSize(.large)
                            
                            Button("ALT Organize (Token-Safe)") {
                                altOrganizeFiles()
                            }
                            .accessibilityIdentifier("altOrganizeButton")
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .disabled(
                                appState.selectedDirectory == nil
                                    || fileProcessor.isProcessing
                                    || altFileProcessor.isProcessing
                                    || !foundationModelsManager.isAvailable
                            )
                            .controlSize(.regular)
                        }
                    }
                    .padding(32)
                    .liquidGlassBackground()
                }
            }

            // Last Result
            if let lastResult = appState.lastOrganizationResult {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Last Organization", systemImage: "clock")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lastResult.summary)
                            .font(.body)

                        HStack {
                            Text(
                                "Duration: \(String(format: "%.1f", lastResult.duration))s"
                            )
                            Spacer()
                            Text(lastResult.timestamp, style: .relative)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .liquidGlassBackground()
                }
                .padding()
                .liquidGlassBackground()
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Helpers ---------------------------------------------------------

    func organizeFiles() {
        guard let directory = appState.selectedDirectory else { return }

        Task {
            do {
                let result = try await fileProcessor.processDirectory(directory)
                appState.lastOrganizationResult = result
                appState.addToHistory(result)
                try metadataStore.saveOrganizationResult(result)  // persist
            } catch {
                showAlert("Organization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func altOrganizeFiles() {
        guard let directory = appState.selectedDirectory else { return }

        Task {
            do {
                let result = try await altFileProcessor.processDirectoryAlt(directory)
                appState.lastOrganizationResult = result
                appState.addToHistory(result)
                try metadataStore.saveOrganizationResult(result)  // persist
            } catch {
                showAlert("ALT Organization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testRestoreManager() {
        guard let directory = appState.selectedDirectory else { 
            showAlert("Please select a directory first")
            return 
        }

        Task {
            do {
                // Step 1: Tag files and create snapshots
                let snapshots = RestoreManager.tagAllFilesInTree(rootURL: directory)
                showAlert("✅ Tagged \(snapshots.count) files with UUIDs")
                
                // Step 2: Create restore file
                let success = RestoreManager.createRestoreFile(at: directory, snapshots: snapshots, useApplicationSupport: true)
                
                if success {
                    // Step 3: Find restore files
                    let restoreFiles = RestoreManager.findRestoreFiles(for: directory)
                    showAlert("✅ Restore file created! Found \(restoreFiles.count) restore files. Now run nuke.sh to test restoration.")
                } else {
                    showAlert("❌ Failed to create restore file")
                }
            } catch {
                showAlert("RestoreManager test failed: \(error.localizedDescription)")
            }
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}


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
    @Environment(\.testFixtureFolder) private var fixturePath     // ← NEW
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @StateObject private var fileProcessor: FileProcessor
    @StateObject private var metadataStore = MetadataStore()
    
    @State private var showingDirectoryPicker = false
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init() {
        // Initialize with a placeholder - will be updated in onAppear
        let placeholder = FoundationModelsManager()
        _fileProcessor = StateObject(wrappedValue: FileProcessor(foundationModelsManager: placeholder))
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
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

                        if let path = fixturePath {                        // test run: folder is predefined
                            appState.selectedDirectory = URL(fileURLWithPath: path)

                        } else {                                           // normal flow: show open-panel
                            let openPanel = NSOpenPanel()
                            openPanel.canChooseDirectories   = true
                            openPanel.canChooseFiles         = false
                            openPanel.allowsMultipleSelection = false
                            openPanel.message = "Select a folder to organize"

                            if openPanel.runModal() == .OK {               // ← removed stray comma here
                                if let selectedURL = openPanel.url {
                                    do {
                                        let bookmark = try selectedURL.bookmarkData(options: .withSecurityScope)
                                        UserDefaults.standard.set(bookmark, forKey: "selectedFolderBookmark")
                                        appState.selectedDirectory = selectedURL
                                    } catch {
                                        print("Failed to create bookmark: \(error)")
                                    }
                                }
                            }
                        }

                    }
                    .buttonStyle(.bordered)            // view modifiers belong outside the action
                    .padding(.horizontal)

                    
                    Divider()
                    
                    // Dry Run Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Dry Run Mode", isOn: $appState.isDryRun)
                            .font(.headline)
                        
                        Text("Preview changes without moving files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Navigation Buttons
                    VStack(spacing: 8) {
                        Button("History") {
                            showingHistory = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Settings") {
                            showingSettings = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .frame(minWidth: 280, maxWidth: 320)
            } // <-- End of sidebar VStack
            
        } detail: {
            // Main Content
            VStack(spacing: 20) {
                // Status Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: foundationModelsManager.isAvailable ? "brain.head.profile" : "exclamationmark.triangle")
                            .foregroundColor(foundationModelsManager.isAvailable ? .green : .orange)
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
                    if fileProcessor.isProcessing {
                        // Processing View
                        VStack(spacing: 12) {
                            ProgressView(value: fileProcessor.progress)
                                .accessibilityIdentifier("organizeProgress")      // ← NEW
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(maxWidth: 400)
                            
                            Text(fileProcessor.currentStatus)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(fileProcessor.progress * 100))% Complete")
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
                            
                            Button("Organize Files") {
                                organizeFiles()
                            }
                            .accessibilityIdentifier("organizeButton")            // ← NEW
                            .buttonStyle(.borderedProminent)
                            .disabled(appState.selectedDirectory == nil || fileProcessor.isProcessing || !foundationModelsManager.isAvailable)
                            .controlSize(.large)
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
                                Text("Duration: \(String(format: "%.1f", lastResult.duration))s")
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
                alertMessage = "Failed to select directory: \(error.localizedDescription)"
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
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Update file processor with the actual foundation models manager
            fileProcessor.foundationModelsManager = foundationModelsManager
            
            // Auto-select fixture when the UI-test injects FIXTURE_PATH
            if let path = fixturePath, appState.selectedDirectory == nil {
                appState.selectedDirectory = URL(fileURLWithPath: path)
            }
            
            // Load organization history
            Task {
                do {
                    appState.organizationHistory = try metadataStore.loadOrganizationHistory()
                } catch {
                    print("Failed to load history: \(error)")
                }
            }
        }
    }
    
    func organizeFiles() {
        guard let directory = appState.selectedDirectory else { return }
        
        Task {
            do {
                let result = try await fileProcessor.processDirectory(
                    directory,
                    isDryRun: appState.isDryRun
                )
                
                appState.lastOrganizationResult = result
                appState.addToHistory(result)
                
                // Save to persistent storage
                try metadataStore.saveOrganizationResult(result)
                
            } catch {
                alertMessage = "Organization failed: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

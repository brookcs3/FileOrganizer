//
//  SettingsView.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @StateObject private var metadataStore = MetadataStore()
    
    @State private var settings = AppSettings()
    @State private var showingClearCacheAlert = false
    @State private var cacheSize: Int64 = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("General") {
                    Picker("Default Sorting Mode", selection: $settings.defaultSortingMode) {
                        ForEach(SortingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    Toggle("Enable Dry Run by Default", isOn: $settings.enableDryRunByDefault)
                    
                    Stepper("Max Files per Batch: \(settings.maxFilesPerBatch)", 
                           value: $settings.maxFilesPerBatch, 
                           in: 10...1000, 
                           step: 10)
                }
                
                Section("Organization") {
                    Picker("Organization Strategy", selection: $settings.organizationStrategy) {
                        ForEach(AppSettings.OrganizationStrategy.allCases, id: \.self) { strategy in
                            Text(strategy.rawValue).tag(strategy)
                        }
                    }
                    
                    Text(settings.organizationStrategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Notifications") {
                    Toggle("Enable Progress Notifications", isOn: $settings.enableProgressNotifications)
                }
                
                Section("Apple Intelligence") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(foundationModelsManager.availabilityStatus)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Available")
                        Spacer()
                        Image(systemName: foundationModelsManager.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(foundationModelsManager.isAvailable ? .green : .red)
                    }
                    
                    if !foundationModelsManager.isAvailable {
                        Text("Apple Intelligence must be enabled in System Settings for AI-powered organization.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Storage") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Analysis Cache") {
                        showingClearCacheAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Built with Apple Foundation Models and inspired by QiuYannnn's Local-File-Organizer methodology.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadSettings()
            updateCacheSize()
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all cached analysis results. You'll need to re-analyze files.")
        }
    }
    
    private func loadSettings() {
        do {
            if let loadedSettings = try metadataStore.loadSettings() {
                settings = loadedSettings
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    private func saveSettings() {
        do {
            try metadataStore.saveSettings(settings)
            
            // Apply settings to app state
            appState.sortingMode = settings.defaultSortingMode
            appState.isDryRun = settings.enableDryRunByDefault
            
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func updateCacheSize() {
        cacheSize = metadataStore.getCacheSize()
    }
    
    private func clearCache() {
        do {
            try metadataStore.clearAnalysisCache()
            updateCacheSize()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}


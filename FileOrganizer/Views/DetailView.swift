//
//  DetailView.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct DetailView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @Bindable var fileProcessor: FileProcessor
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
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
                if fileProcessor.isProcessing {
                    ProcessingView(fileProcessor: fileProcessor)
                } else {
                    IdleView(
                        appState: appState,
                        fileProcessor: fileProcessor,
                        showingAlert: $showingAlert,
                        alertMessage: $alertMessage
                    )
                }
            }
            .liquidGlassBackground()

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

@available(macOS 26.0, *)
struct ProcessingView: View {
    @Bindable var fileProcessor: FileProcessor
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: fileProcessor.progress)
                .accessibilityIdentifier("organizeProgress")
                .progressViewStyle(.linear)
                .frame(maxWidth: 400)

            Text(fileProcessor.currentStatus)
                .font(.body)
                .multilineTextAlignment(.center)

            Text(String(format: "%.0f%% Complete", fileProcessor.progress * 100))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

@available(macOS 26.0, *)
struct IdleView: View {
    @Bindable var appState: AppState
    @Bindable var fileProcessor: FileProcessor
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Ready to Organize")
                    .font(.title)
                    .fontWeight(.medium)

                Text("Select a directory and click organize to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await organizeFiles()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Organize Files")
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.selectedDirectory == nil)
            .accessibilityIdentifier("organizeButton")

            if let directory = appState.selectedDirectory {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will organize:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(directory.path)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                .frame(maxWidth: 400)
            }
        }
        .padding()
    }
    
    private func organizeFiles() async {
        guard let directory = appState.selectedDirectory else {
            alertMessage = "Please select a directory first."
            showingAlert = true
            return
        }

        do {
            let result = try await fileProcessor.processDirectory(directory)
            alertMessage = "✅ Organization complete!\n\n\(result.summary)"
            showingAlert = true
        } catch {
            alertMessage = "❌ Organization failed:\n\n\(error.localizedDescription)"
            showingAlert = true
        }
    }
}

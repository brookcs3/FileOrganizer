//
//  SidebarView.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var showingDirectoryPicker: Bool
    @Binding var showingHistory: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
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
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("No directory selected")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Button("Select Directory") {
                    showingDirectoryPicker = true
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Divider()

            // Navigation
            VStack(alignment: .leading, spacing: 8) {
                Label("Quick Actions", systemImage: "sparkles")
                    .font(.headline)

                Button {
                    showingHistory = true
                } label: {
                    HStack {
                        Image(systemName: "clock")
                        Text("Organization History")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)

                Button {
                    showingSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
            .padding(.horizontal)

            Spacer()

            // Version Info
            VStack(alignment: .leading, spacing: 4) {
                Text("FileOrganizer v1.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Built with Apple Intelligence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }
}

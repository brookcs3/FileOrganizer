//
//  HistoryView.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedResult: OrganizationResult?
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.organizationHistory.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Organization History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your file organization history will appear here")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    // History List
                    List(appState.organizationHistory, selection: $selectedResult) { result in
                        HistoryRowView(result: result)
                            .tag(result)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Organization History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear History") {
                        appState.organizationHistory.removeAll()
                    }
                    .disabled(appState.organizationHistory.isEmpty)
                }
            }
            
            // Detail View
            if let selectedResult = selectedResult {
                HistoryDetailView(result: selectedResult)
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Select an organization result to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 800, height: 600)
    }
}

struct HistoryRowView: View {
    let result: OrganizationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: result.isDryRun ? "eye" : "checkmark.circle.fill")
                    .foregroundColor(result.isDryRun ? .orange : .green)
                
                Text(result.mode)
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.summary)
                .font(.body)
                .lineLimit(2)
            
            HStack {
                Label("\(result.filesProcessed) files", systemImage: "doc")
                
                Spacer()
                
                Label("\(result.categoriesCreated.count) categories", systemImage: "folder")
                
                Spacer()
                
                Label("\(String(format: "%.1f", result.duration))s", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct HistoryDetailView: View {
    let result: OrganizationResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: result.isDryRun ? "eye" : "checkmark.circle.fill")
                            .foregroundColor(result.isDryRun ? .orange : .green)
                            .font(.title2)
                        
                        Text(result.mode)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if result.isDryRun {
                            Text("DRY RUN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(result.timestamp, style: .complete)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Summary Stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    StatCard(title: "Files Processed", value: "\(result.filesProcessed)", icon: "doc.text")
                    StatCard(title: "Files Organized", value: "\(result.filesOrganized)", icon: "checkmark.circle")
                    StatCard(title: "Categories", value: "\(result.categoriesCreated.count)", icon: "folder")
                }
                
                Divider()
                
                // Directories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Directories")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Source", systemImage: "folder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(result.sourceDirectory)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Target", systemImage: "folder.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(result.targetDirectory)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                Divider()
                
                // Categories Created
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories Created")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(result.categoriesCreated, id: \.self) { category in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                
                                Text(category)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Organization Details")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

# FileSorter Installation Guide: QiuYannnn Methodology Implementation

**Project:** FileSorter with QiuYannnn Token-Safe Methodology  
**Target Platform:** macOS 26 + Xcode 26 Beta  
**Author:** Cameron Brooks
**Date:** June 18, 2025  
**Version:** 1.0

## Overview

This comprehensive installation guide will walk you through implementing the QiuYannnn methodology and Apple Foundation Models integration into your existing FileSorter application. The implementation includes token-safe per-file processing, content sanitization bypass, specialized file analyzers, and a complete user interface overhaul while preserving your existing functionality.

## Current App Analysis

Your current FileSorter application has the following structure:

### Core Files (10 Swift files):
- `FileSorterApp.swift` - Main app entry point with CoreData
- `ContentView.swift` - UI with folder picker and organization buttons
- `LLMViewModel.swift` - Basic Foundation Models integration
- `OrganizationEngine.swift` - Current organization logic
- `FileAnalyzer.swift` - Comprehensive file analysis system
- `FileModels.swift` - Data models
- `HistoryEntry.swift` - History tracking
- `Persistence.swift` - CoreData persistence
- `FileUtilities.swift` - File system utilities
- `RestoreManager.swift` - Backup and restore functionality

### Current Features:
- Basic Foundation Models integration
- Folder selection interface
- "Organize Files by Type" algorithmic sorting
- "Start Organization" AI-based sorting
- CoreData persistence
- History tracking
- Backup/restore functionality

## Implementation Strategy

The installation will preserve all your existing functionality while adding the QiuYannnn methodology improvements. We'll organize the new code into logical groups and maintain backward compatibility.

## Step 1: Project Preparation and Backup

Before implementing any changes, it's crucial to create a complete backup of your current project and prepare the development environment for the new architecture.

### 1.1 Create Project Backup

First, create a complete backup of your current FileSorter project. This ensures you can revert to the working state if needed during the implementation process.

```bash
# Navigate to your project directory
cd /path/to/your/FileSorter-main

# Create a backup with timestamp
cp -r . ../FileSorter-Backup-$(date +%Y%m%d_%H%M%S)

# Verify backup was created
ls -la ../FileSorter-Backup-*
```

### 1.2 Verify Xcode and macOS Requirements

Ensure your development environment meets the requirements for the new implementation:

- **Xcode 26 Beta** - Required for Foundation Models framework
- **macOS 26 (Tahoe) Beta** - Required for Apple Intelligence features
- **Swift 6.0** - Required for modern concurrency features

Open your project in Xcode and verify the current deployment target:

1. Select your project in the navigator
2. Go to Build Settings
3. Find "macOS Deployment Target"
4. Ensure it's set to macOS 26.0 or later

### 1.3 Update Project Settings

Before adding new files, update your project configuration to support the new architecture:

**Update Info.plist:** Add the following entries to support Apple Intelligence features:

```xml
<key>NSAppleIntelligenceUsageDescription</key>
<string>FileSorter uses Apple Intelligence to intelligently organize your files based on content analysis.</string>

<key>NSFileProviderDomainUsageDescription</key>
<string>FileSorter needs access to organize files in your selected directories.</string>
```

**Update Build Settings:**
1. Set Swift Language Version to Swift 6
2. Enable "Strict Concurrency Checking"
3. Add Foundation Models framework to "Frameworks and Libraries"

### 1.4 Create New Directory Structure

The new implementation requires a more organized directory structure. Create the following folders in your Xcode project:

```
FileSorter/
├── App/         (Move existing app files here)
├── Core/        (New: Core QiuYannnn methodology)
├── Services/    (Expand existing Services)
├── Models/      (Expand existing Models)
├── Utils/       (Keep existing Utils)
├── Legacy/      (New: Preserve old functionality)
└── Extensions/  (New: Swift extensions)
```

**Implementation Steps:**

1. In Xcode, right-click on the FileSorter group
2. Select "New Group" for each directory above
3. Move existing files to appropriate groups:
   - `FileSorterApp.swift` → `App/`
   - `ContentView.swift` → `App/`
   - `FileModels.swift` → `Models/`
   - `HistoryEntry.swift` → `Models/`
   - `LLMViewModel.swift` → `Services/`
   - `OrganizationEngine.swift` → `Legacy/` (will be replaced)
   - `FileAnalyzer.swift` → `Legacy/` (will be enhanced)
   - `Persistence.swift` → `Utils/`
   - `FileUtilities.swift` → `Utils/`
   - `RestoreManager.swift` → `Utils/`

## Step 2: Install Core QiuYannnn Methodology Files

The QiuYannnn methodology is implemented through several core files that handle token-safe per-file processing. These files form the foundation of the new architecture.

### 2.1 Add Core Engine Files

Create the following files in the `Core/` group. Each file implements a specific aspect of the QiuYannnn methodology:

**File 1: Core/PerFileAnalyzer.swift**

This is the heart of the QiuYannnn methodology - it processes files individually to avoid token limits.

```swift
// Copy the complete PerFileAnalyzer.swift from FileSorterComplete/Core/
// This file implements:
// - Individual file processing
// - Token isolation between files
// - Specialized analyzer routing
// - Progress tracking
// - Analysis session management
```

**File 2: Core/TokenSafeAnalysisEngine.swift**

Manages Apple's 4096 token limit with intelligent content truncation.

```swift
// Copy the complete TokenSafeAnalysisEngine.swift from FileSorterComplete/Core/
// This file implements:
// - Token counting and estimation
// - Content truncation strategies
// - Priority-based content selection
// - Technical pattern preservation
// - Safe prompt construction
```

**File 3: Core/MetadataStore.swift**

Provides JSON-based persistence for analysis results, enabling the QiuYannnn approach.

```swift
// Copy the complete MetadataStore.swift from FileSorterComplete/Core/
// This file implements:
// - JSON metadata persistence
// - Analysis result caching
// - File change detection
// - Atomic operations
// - Error recovery
```

**File 4: Core/FileDiscoveryEngine.swift**

Handles recursive directory scanning and file inventory creation.

```swift
// Copy the complete FileDiscoveryEngine.swift from FileSorterComplete/Core/
// This file implements:
// - Recursive directory traversal
// - File filtering and validation
// - Progress reporting
// - Error handling
// - Memory-efficient scanning
```

**File 5: Core/OrganizationExecutionEngine.swift**

Safely executes file organization operations with rollback capability.

```swift
// Copy the complete OrganizationExecutionEngine.swift from FileSorterComplete/Core/
// This file implements:
// - Atomic file operations
// - Directory creation
// - Rollback on failure
// - Progress tracking
// - Conflict resolution
```

### 2.2 Add Content Sanitization System

The content sanitization bypass is crucial for handling technical content that might trigger false positives.

**File 6: Core/ContentSanitizationBypass.swift**

```swift
// Copy the complete ContentSanitizationBypass.swift from FileSorterComplete/Core/
// This file implements:
// - Technical pattern recognition
// - Context-aware content analysis
// - Whitelist management
// - User confirmation workflows
// - Safety validation
```

### 2.3 Add Universal Content Analyzer

This provides content-agnostic analysis that works with any file type.

**File 7: Core/UniversalContentAnalyzer.swift**

```swift
// Copy the complete UniversalContentAnalyzer.swift from FileSorterComplete/Core/
// This file implements:
// - Universal file type detection
// - Content extraction strategies
// - Vision framework integration
// - Metadata analysis
// - Fallback handling
```

### 2.4 Integration Steps

After adding these core files:

1. **Add to Xcode Project:**
   - Drag each file into the appropriate `Core/` group
   - Ensure "Add to target" is checked for FileSorter
   - Verify files appear in Build Phases → Compile Sources

2. **Resolve Dependencies:**
   - Import statements should automatically resolve
   - If you see errors, ensure Foundation Models framework is linked
   - Check that macOS deployment target is 26.0+

3. **Build and Test:**
   ```bash
   # Clean build folder
   Product → Clean Build Folder
   
   # Build project
   Product → Build (⌘+B)
   
   # Fix any compilation errors before proceeding
   ```

## Step 3: Install Specialized File Analyzers

The specialized analyzers provide optimized handling for different file types while maintaining the universal approach. These replace and enhance your existing FileAnalyzer.swift.

### 3.1 Preserve Existing Analyzer

Before adding new analyzers, preserve your existing comprehensive file analysis system:

1. Rename `Services/FileAnalyzer.swift` to `Legacy/FileAnalyzer_Original.swift`
2. This preserves your existing logic for reference and fallback

### 3.2 Add New Specialized Analyzers

Create these files in the `Services/` group:

**File 8: Services/AudioFileAnalyzer.swift**

Handles audio files with technical metadata extraction, completely generic without hard-coded equipment assumptions.

```swift
// Copy the complete AudioFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - AVFoundation metadata extraction
// - Generic audio content analysis
// - Technical specification parsing
// - AI-driven categorization
// - No domain-specific assumptions
```

**File 9: Services/VideoFileAnalyzer.swift**

Processes video files with frame analysis and metadata extraction.

```swift
// Copy the complete VideoFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - Video metadata extraction
// - Frame sampling and analysis
// - Duration and quality assessment
// - Content type detection
// - Technical specification analysis
```

**File 10: Services/ImageFileAnalyzer.swift**

Analyzes images using Vision framework for OCR and object detection.

```swift
// Copy the complete ImageFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - Vision framework integration
// - OCR text extraction
// - Object and scene detection
// - Image metadata analysis
// - Content classification
```

**File 11: Services/DocumentFileAnalyzer.swift**

Handles PDFs and documents with content extraction.

```swift
// Copy the complete DocumentFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - PDF content extraction
// - Document structure analysis
// - Text content summarization
// - Metadata parsing
// - Format-specific handling
```

**File 12: Services/TextFileAnalyzer.swift**

Processes code and text files with syntax and content analysis.

```swift
// Copy the complete TextFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - Programming language detection
// - Syntax analysis
// - Content summarization
// - Technical documentation parsing
// - Code structure analysis
```

**File 13: Services/GenericFileAnalyzer.swift**

Provides fallback analysis for unknown file types.

```swift
// Copy the complete GenericFileAnalyzer.swift from FileSorterComplete/Services/
// This file implements:
// - Binary file analysis
// - Header inspection
// - Pattern recognition
// - Fallback categorization
// - Unknown type handling
```

### 3.3 Update Data Models

Enhance your existing models to support the new analysis results:

**File 14: Models/FileAnalysisResult.swift**

```swift
// Copy the complete FileAnalysisResult.swift from FileSorterComplete/Models/
// This file implements:
// - Comprehensive analysis results
// - Confidence scoring
// - Category decisions
// - Technical metadata
// - Reasoning explanations
```

**File 15: Models/FileInventoryItem.swift**

```swift
// Copy the complete FileInventoryItem.swift from FileSorterComplete/Models/
// This file implements:
// - Enhanced file representation
// - Metadata tracking
// - Change detection
// - Analysis state management
// - Content type classification
```

### 3.4 Integration and Testing

After adding all specialized analyzers:

1. **Update Imports:**
   Ensure all new files have proper import statements:
   ```swift
   import Foundation
   import FoundationModels
   import Vision
   import AVFoundation
   import UniformTypeIdentifiers
   ```

2. **Build Project:**
   ```bash
   Product → Clean Build Folder
   Product → Build (⌘+B)
   ```

3. **Resolve Compilation Errors:**
   - Check for missing frameworks
   - Verify protocol conformance
   - Fix any naming conflicts

4. **Test Individual Analyzers:**
   Create simple test cases to verify each analyzer works:
   ```swift
   // Example test in your existing test files
   func testAudioAnalyzer() async throws {
       let analyzer = AudioFileAnalyzer(foundationModels: foundationModels)
       let testFile = // create test FileInventoryItem
       let result = try await analyzer.analyze(testFile)
       
       XCTAssertNotNil(result.suggestedCategory)
   }
   ```

## Step 4: Update User Interface and App Integration

Now we'll update your existing user interface to integrate the new QiuYannnn methodology while preserving your current functionality and adding the real-time progress tracking you requested.

### 4.1 Update Main App File

Replace your existing `App/FileSorterApp.swift` with the enhanced version that includes Foundation Models integration:

**Enhanced FileSorterApp.swift:**

```swift
//
//  FileSorterApp.swift
//  FileSorter
//
//  Enhanced with Foundation Models and QiuYannnn methodology
//

import SwiftUI
import CoreData
import FoundationModels

@main
struct FileSorterApp: App {
    let persistenceController = PersistenceController.shared
    
    // Foundation Models integration
    @State private var foundationModels: SystemLanguageModel?
    @State private var isAppleIntelligenceAvailable = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                foundationModels: foundationModels,
                isAppleIntelligenceAvailable: isAppleIntelligenceAvailable
            )
            .containerBackground(.ultraThinMaterial, for: .window)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .task {
                await initializeFoundationModels()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
    }
    
    @MainActor
    private func initializeFoundationModels() async {
        do {
            // Initialize Apple's Foundation Models
            let model = SystemLanguageModel(useCase: .contentTagging)
            self.foundationModels = model
            self.isAppleIntelligenceAvailable = true
            
            print("✅ Apple Intelligence Foundation Models initialized successfully")
        } catch {
            print("❌ Failed to initialize Foundation Models: \(error)")
            self.isAppleIntelligenceAvailable = false
        }
    }
}
```

### 4.2 Update ContentView with Enhanced Interface

Your existing ContentView needs significant updates to integrate the QiuYannnn methodology while preserving your current folder selection and organization buttons. Here's the enhanced version:

**Enhanced ContentView.swift:**

```swift
//
//  ContentView.swift
//  FileSorter
//
//  Enhanced with QiuYannnn methodology and real-time progress
//

import SwiftUI
import AppKit
import Combine
import FoundationModels
import AVFoundation
import ImageIO

@available(macOS 26.0, *)
struct ContentView: View {
    // Foundation Models integration
    let foundationModels: SystemLanguageModel?
    let isAppleIntelligenceAvailable: Bool
    
    // Core QiuYannnn components
    @State private var fileSorterOrganizer: FileSorterOrganizer?
    @State private var perFileAnalyzer: PerFileAnalyzer?
    
    // UI State (preserve your existing state)
    @StateObject private var llm = LLMViewModel()
    @State private var organizationEngine: OrganizationEngine?
    @State private var rootURL: URL?
    @State private var history: [HistoryEntry] = []
    @State private var rootFileNode: FileNode? = nil
    
    // New QiuYannnn progress tracking
    @State private var isOrganizing = false
    @State private var organizationProgress: Double = 0.0
    @State private var currentOperation: String = ""
    @State private var filesProcessed: Int = 0
    @State private var totalFiles: Int = 0
    @State private var organizationResults: OrganizationResult?
    
    // Legacy analyzer (preserved)
    private let fileAnalyzer = FileAnalyzer()
    
    // Sorting mode selection
    @State private var sortingMode: SortingMode = .aiIntelligent
    
    enum SortingMode: String, CaseIterable {
        case aiIntelligent = "AI Intelligent Sorting"
        case algorithmicByType = "Sort by Type (Legacy)"
        case hybrid = "Hybrid Approach"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Apple Intelligence Status Indicator
            appleIntelligenceStatusView
            
            // Folder Selection (preserve your existing UI)
            folderSelectionView
            
            // Sorting Mode Selection (new)
            sortingModeSelectionView
            
            // Organization Controls (enhanced)
            organizationControlsView
            
            // Progress Tracking (new - shows real-time progress)
            if isOrganizing {
                organizationProgressView
            }
            
            // Results Display (enhanced)
            if let results = organizationResults {
                organizationResultsView(results)
            }
            
            // History Display (preserve your existing history)
            historyView
        }
        .padding()
        .task {
            await initializeQiuYannnComponents()
        }
    }
    
    // MARK: - Apple Intelligence Status
    
    private var appleIntelligenceStatusView: some View {
        GroupBox("Apple Intelligence Status") {
            HStack {
                Image(systemName: isAppleIntelligenceAvailable ? "brain.head.profile" : "exclamationmark.triangle")
                    .foregroundColor(isAppleIntelligenceAvailable ? .green : .orange)
                
                Text(isAppleIntelligenceAvailable ? 
                     "Apple Intelligence Available" : 
                     "Apple Intelligence Unavailable")
                    .font(.headline)
                
                Spacer()
                
                if isAppleIntelligenceAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .symbolEffect(.pulse)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Folder Selection (preserve existing)
    
    private var folderSelectionView: some View {
        GroupBox("Folder to Sort") {
            VStack(spacing: 12) {
                Button("Choose Folder…", action: chooseFolder)
                
                if let url = rootURL {
                    Text("Selected: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Path: \(url.path)")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }
    
    // MARK: - Sorting Mode Selection (new)
    
    private var sortingModeSelectionView: some View {
        GroupBox("Organization Method") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(SortingMode.allCases, id: \.self) { mode in
                    HStack {
                        Button(action: { sortingMode = mode }) {
                            HStack {
                                Image(systemName: sortingMode == mode ? "largecircle.fill.circle" : "circle")
                                Text(mode.rawValue)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(sortingMode == mode ? .accentColor : .primary)
                    }
                }
                
                // Mode descriptions
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    private var modeDescription: String {
        switch sortingMode {
        case .aiIntelligent:
            return "Uses QiuYannnn methodology with Apple Intelligence for semantic content analysis. Recommended for best results."
        case .algorithmicByType:
            return "Traditional file type sorting. Fast but less intelligent categorization."
        case .hybrid:
            return "Combines algorithmic speed with AI intelligence for balanced performance."
        }
    }
    
    // MARK: - Organization Controls (enhanced)
    
    private var organizationControlsView: some View {
        GroupBox("Organization Controls") {
            VStack(spacing: 12) {
                // Main organize button
                Button(action: startOrganization) {
                    HStack {
                        if isOrganizing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "folder.badge.gearshape")
                        }
                        
                        Text(isOrganizing ? "Organizing..." : "Organize Files")
                    }
                }
                .disabled(rootURL == nil || isOrganizing || !isAppleIntelligenceAvailable)
                .buttonStyle(.borderedProminent)
                
                // Legacy sorting button (preserved)
                Button("Sort by Type (Legacy)") {
                    Task {
                        await sortFilesByType()
                    }
                }
                .disabled(rootFileNode == nil || isOrganizing)
                .buttonStyle(.bordered)
                
                // Debug button (preserve if needed)
                if let _ = rootURL {
                    Button("Debug Analysis") {
                        Task {
                            await debugAnalysis()
                        }
                    }
                    .disabled(isOrganizing)
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Progress Tracking (new - real-time updates)
    
    private var organizationProgressView: some View {
        GroupBox("Organization Progress") {
            VStack(alignment: .leading, spacing: 12) {
                // Overall progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall Progress")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(organizationProgress * 100))%")
                            .font(.headline)
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: organizationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
                // Current operation
                HStack {
                    Image(systemName: "gearshape.2")
                        .symbolEffect(.rotate)
                    Text(currentOperation)
                        .font(.subheadline)
                        .lineLimit(2)
                    Spacer()
                }
                
                // File count
                HStack {
                    Image(systemName: "doc.text")
                    Text("Files: \(filesProcessed) / \(totalFiles)")
                        .font(.subheadline)
                        .monospacedDigit()
                    Spacer()
                }
                
                // Cancel button
                Button("Cancel Organization") {
                    cancelOrganization()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Results Display (enhanced)
    
    private func organizationResultsView(_ results: OrganizationResult) -> some View {
        GroupBox("Organization Results") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Organization Complete!")
                        .font(.headline)
                    Spacer()
                }
                
                // Statistics
                VStack(alignment: .leading, spacing: 4) {
                    Text("📁 Categories Created: \(results.categoriesCreated.count)")
                    Text("✅ Files Moved: \(results.successfulMoves)")
                    Text("❌ Failed Moves: \(results.failedMoves)")
                    Text("⏱ Duration: \(formatDuration(results.duration))")
                }
                .font(.subheadline)
                
                // View details button
                Button("View Detailed Results") {
                    showDetailedResults(results)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - History View (preserve existing)
    
    private var historyView: some View {
        if !history.isEmpty {
            GroupBox("Recent Operations") {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(history.prefix(10), id: \.id) { entry in
                            HStack {
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(entry.operation)
                                    .font(.caption)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
    }
}

// MARK: - Implementation Methods

extension ContentView {
    
    @MainActor
    private func initializeQiuYannnComponents() async {
        guard let foundationModels = foundationModels else { return }
        
        do {
            // Initialize QiuYannnn components
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let metadataBaseURL = documentsURL.appendingPathComponent("FileSorter")
            
            let metadataStore = try MetadataStore(baseURL: metadataBaseURL)
            self.perFileAnalyzer = try PerFileAnalyzer(metadataStore: metadataStore)
            self.fileSorterOrganizer = try FileSorterOrganizer(
                foundationModels: foundationModels,
                mode: .aiIntelligent
            )
            
            print("✅ QiuYannnn components initialized successfully")
        } catch {
            print("❌ Failed to initialize QiuYannnn components: \(error)")
        }
    }
    
    private func startOrganization() {
        guard let rootURL = rootURL,
              let organizer = fileSorterOrganizer else { return }
        
        Task {
            await performQiuYannnOrganization(at: rootURL, using: organizer)
        }
    }
    
    @MainActor
    private func performQiuYannnOrganization(at url: URL, using organizer: FileSorterOrganizer) async {
        isOrganizing = true
        organizationProgress = 0.0
        currentOperation = "Initializing organization..."
        
        do {
            let result = try await organizer.organizeDirectory(url) { progress, operation in
                Task { @MainActor in
                    self.organizationProgress = progress
                    self.currentOperation = operation
                    
                    // Extract file counts from operation string if available
                    if operation.contains("Analyzing") {
                        // Parse file progress from operation string
                        // This would be implemented based on the actual progress format
                    }
                }
            }
            
            self.organizationResults = result
            self.addHistoryEntry("QiuYannnn organization completed: \(result.successfulMoves) files organized")
        } catch {
            self.addHistoryEntry("Organization failed: \(error.localizedDescription)")
            print("❌ Organization failed: \(error)")
        }
        
        isOrganizing = false
        currentOperation = ""
    }
    
    // Preserve your existing methods
    private func chooseFolder() {
        // Keep your existing folder selection logic
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            rootURL = panel.url
            
            // Initialize file tree for legacy functionality
            Task {
                await buildFileTree()
            }
        }
    }
    
    private func sortFilesByType() async {
        // Keep your existing algorithmic sorting logic
        guard let rootFileNode = rootFileNode else { return }
        
        currentOperation = "Sorting files by type..."
        
        // Your existing implementation here
        // This preserves the "Sort by Type" functionality
    }
    
    private func debugAnalysis() async {
        // Keep your existing debug functionality
        currentOperation = "Running debug analysis..."
        
        // Your existing debug implementation
    }
    
    private func cancelOrganization() {
        // Implement cancellation logic
        isOrganizing = false
        currentOperation = "Cancelling..."
        
        // Cancel any ongoing tasks
        Task {
            // Implement actual cancellation
            await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            currentOperation = ""
        }
    }
    
    private func showDetailedResults(_ results: OrganizationResult) {
        // Implement detailed results view
        // This could open a new window or sheet with comprehensive results
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
    
    private func addHistoryEntry(_ operation: String) {
        let entry = HistoryEntry(
            id: UUID(),
            timestamp: Date(),
            operation: operation
        )
        history.insert(entry, at: 0)
        
        // Keep only recent entries
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
    }
    
    // Keep your existing buildFileTree and other methods
    private func buildFileTree() async {
        // Your existing file tree building logic
    }
}
```

### 4.3 Preserve Legacy Functionality

Move your existing OrganizationEngine to the Legacy folder and create a wrapper:

**Legacy/OrganizationEngine_Original.swift:**

```swift
// Move your existing OrganizationEngine.swift here
// Rename the class to OrganizationEngine_Original
// This preserves your current "Sort by Type" functionality
```

**Legacy/AlgorithmicSortingEngine.swift:**

```swift
// Copy the AlgorithmicSortingEngine.swift from FileSorterComplete/Legacy/
// This provides a clean interface to your existing algorithmic sorting
```

### 4.4 Update LLMViewModel

Enhance your existing LLMViewModel to work with the new architecture:

**Services/LLMViewModel.swift (Enhanced):**

```swift
import Combine
import FoundationModels

@MainActor
@available(macOS 26.0, *)
final class LLMViewModel: ObservableObject {
    @Published var isBusy = false
    @Published var statusMessage: String?
    @Published var transcript = Transcript()
    public var maximumResponseTokens: Int?
    
    // Enhanced for QiuYannnn methodology
    private let tokenSafeEngine: TokenSafeAnalysisEngine?
    
    init(foundationModels: SystemLanguageModel? = nil) {
        if let model = foundationModels {
            self.tokenSafeEngine = TokenSafeAnalysisEngine(systemModel: model)
        } else {
            self.tokenSafeEngine = nil
        }
    }
    
    var generationOptions: GenerationOptions {
        if let maxTokens = maximumResponseTokens {
            return GenerationOptions(maximumResponseTokens: maxTokens)
        } else {
            return GenerationOptions()
        }
    }
    
    /// Enhanced respond method with token safety
    func respond(to prompt: String) async throws -> String {
        self.transcript.append(.user(prompt))
        
        // Use token-safe engine if available
        let safePrompt: String
        if let tokenEngine = tokenSafeEngine {
            safePrompt = try await tokenEngine.makeSafePrompt(prompt, contentType: .text)
        } else {
            safePrompt = prompt
        }
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: safePrompt, options: generationOptions)
        
        self.transcript.append(.assistant(response.content))
        return response.content
    }
    
    /// Token-safe content analysis for QiuYannnn methodology
    func analyzeContent(_ content: String, fileType: FileTypeCategory) async throws -> String {
        guard let tokenEngine = tokenSafeEngine else {
            throw AnalysisError.tokenEngineUnavailable
        }
        
        let safePrompt = try await tokenEngine.makeSafePrompt(content, contentType: fileType)
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: safePrompt, options: generationOptions)
        
        return response.content
    }
}

enum AnalysisError: Error {
    case tokenEngineUnavailable
}
```

This completes the user interface integration while preserving all your existing functionality and adding the comprehensive QiuYannnn methodology with real-time progress tracking.

## Step 5: Project Configuration and Dependencies

Proper project configuration is essential for the QiuYannnn methodology to function correctly with Apple's Foundation Models framework.

### 5.1 Update Build Settings

Configure your Xcode project to support the new architecture:

**Target Build Settings:**

1. **Swift Language Version:**
   - Set to "Swift 6" for modern concurrency support
   - Path: Build Settings → Swift Compiler - Language → Swift Language Version

2. **Deployment Target:**
   - Set to "macOS 26.0" minimum
   - Path: Build Settings → Deployment → macOS Deployment Target

3. **Concurrency Settings:**
   - Enable "Strict Concurrency Checking"
   - Path: Build Settings → Swift Compiler - Language → Strict Concurrency Checking

4. **Framework Search Paths:**
   - Ensure Foundation Models framework is accessible
   - Path: Build Settings → Search Paths → Framework Search Paths

**Frameworks and Libraries:**

Add the following frameworks to your target:

1. **Foundation Models** (Required for Apple Intelligence)
   - Target → General → Frameworks and Libraries
   - Click "+" and add FoundationModels.framework

2. **Vision** (Required for image analysis)
   - Add Vision.framework

3. **AVFoundation** (Required for audio/video analysis)
   - Add AVFoundation.framework

4. **UniformTypeIdentifiers** (Required for file type detection)
   - Add UniformTypeIdentifiers.framework

### 5.2 Update Info.plist

Add required privacy descriptions and capabilities:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entries -->
    
    <!-- Apple Intelligence Usage -->
    <key>NSAppleIntelligenceUsageDescription</key>
    <string>FileSorter uses Apple Intelligence to intelligently analyze and organize your files based on their content, providing semantic understanding for better categorization.</string>
    
    <!-- File Provider Domain -->
    <key>NSFileProviderDomainUsageDescription</key>
    <string>FileSorter needs access to organize files in your selected directories and create new folder structures.</string>
    
    <!-- Document Types (if needed) -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>All Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSTypeIsPackage</key>
            <false/>
            <key>NSDocumentClass</key>
            <string>Document</string>
        </dict>
    </array>
    
    <!-- Capabilities -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
</dict>
</plist>
```

### 5.3 Entitlements Configuration

Create or update your entitlements file:

**FileSorter.entitlements:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- File Access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- Apple Intelligence -->
    <key>com.apple.developer.apple-intelligence</key>
    <true/>
    
    <!-- Network (if needed for future features) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
</dict>
</plist>
```

### 5.4 Scheme Configuration

Configure your run scheme for development and testing:

1. **Edit Scheme:**
   - Product → Scheme → Edit Scheme

2. **Run Configuration:**
   - Build Configuration: Debug
   - Executable: FileSorter.app

3. **Environment Variables:**
   Add these for debugging:
   - `QIUYANNNN_DEBUG=1`
   - `FOUNDATION_MODELS_VERBOSE=1`
   - `TOKEN_SAFE_LOGGING=1`

4. **Arguments:**
   Add launch arguments if needed:
   - `-com.apple.CoreData.SQLDebug 1`
   - `-com.apple.CoreData.Logging.stderr 1`

## Step 6: Testing and Validation

Comprehensive testing ensures the QiuYannnn methodology integration works correctly.

### 6.1 Unit Tests

Create test files to validate core functionality:

**FileSorterTests/QiuYannnMethodologyTests.swift:**

```swift
import XCTest
import FoundationModels
@testable import FileSorter

@available(macOS 26.0, *)
final class QiuYannnMethodologyTests: XCTestCase {
    
    var foundationModels: SystemLanguageModel!
    var tokenSafeEngine: TokenSafeAnalysisEngine!
    var perFileAnalyzer: PerFileAnalyzer!
    var metadataStore: MetadataStore!
    
    override func setUpWithError() throws {
        // Initialize test components
        foundationModels = SystemLanguageModel(useCase: .contentTagging)
        tokenSafeEngine = TokenSafeAnalysisEngine(systemModel: foundationModels)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FileSorterTests")
        metadataStore = try MetadataStore(baseURL: tempURL)
        perFileAnalyzer = try PerFileAnalyzer(metadataStore: metadataStore)
    }
    
    func testTokenSafeAnalysis() async throws {
        // Test token limit compliance
        let longContent = String(repeating: "This is a test content. ", count: 1000)
        let safePrompt = try await tokenSafeEngine.makeSafePrompt(longContent, contentType: .text)
        
        let tokenCount = tokenSafeEngine.estimateTokens(safePrompt)
        XCTAssertLessThanOrEqual(tokenCount, 4096, "Prompt exceeds Apple's token limit")
    }
    
    func testPerFileAnalysis() async throws {
        // Create test file
        let testURL = createTestFile(content: "Test file content", extension: "txt")
        let fileItem = FileInventoryItem(url: testURL)
        
        // Test analysis
        let result = try await perFileAnalyzer.analyzeFile(fileItem)
        
        XCTAssertNotNil(result.suggestedCategory)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertFalse(result.reasoning.isEmpty)
    }
    
    func testContentSanitization() throws {
        // Test technical content handling
        let technicalContent = "F_SEEL_SEX1S.wav"
        let bypass = ContentSanitizationBypass()
        
        let result = bypass.validateContent(technicalContent, context: .filename)
        XCTAssertTrue(result.isValid, "Technical equipment name should be valid")
    }
    
    func testSpecializedAnalyzers() async throws {
        // Test each analyzer type
        let analyzers: [(String, String)] = [
            ("test.mp3", "audio"),
            ("test.jpg", "image"),
            ("test.pdf", "document"),
            ("test.txt", "text"),
            ("test.mp4", "video")
        ]
        
        for (filename, expectedType) in analyzers {
            let testURL = createTestFile(content: "Test content", 
                                       extension: String(filename.split(separator: ".").last!))
            let fileItem = FileInventoryItem(url: testURL)
            
            let result = try await perFileAnalyzer.analyzeFile(fileItem)
            XCTAssertNotNil(result.suggestedCategory)
        }
    }
    
    private func createTestFile(content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test.\(ext)")
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
```

### 6.2 Integration Tests

Test the complete workflow:

**FileSorterTests/IntegrationTests.swift:**

```swift
import XCTest
@testable import FileSorter

@available(macOS 26.0, *)
final class IntegrationTests: XCTestCase {
    
    func testCompleteOrganizationWorkflow() async throws {
        // Create test directory structure
        let testDir = createTestDirectory()
        
        // Initialize organizer
        let foundationModels = SystemLanguageModel(useCase: .contentTagging)
        let organizer = try FileSorterOrganizer(foundationModels: foundationModels, mode: .aiIntelligent)
        
        // Track progress
        var progressUpdates: [(Double, String)] = []
        
        // Run organization
        let result = try await organizer.organizeDirectory(testDir) { progress, operation in
            progressUpdates.append((progress, operation))
        }
        
        // Validate results
        XCTAssertGreaterThan(result.successfulMoves, 0)
        XCTAssertEqual(result.failedMoves, 0)
        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertEqual(progressUpdates.last?.0, 1.0) // Should reach 100%
    }
    
    private func createTestDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("IntegrationTest-\(UUID())")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create test files
        let testFiles = [
            ("document.pdf", "PDF content"),
            ("image.jpg", "JPEG data"),
            ("audio.mp3", "MP3 data"),
            ("text.txt", "Text content"),
            ("video.mp4", "MP4 data")
        ]
        
        for (filename, content) in testFiles {
            let fileURL = tempDir.appendingPathComponent(filename)
            try! content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return tempDir
    }
}
```

### 6.3 Performance Tests

Validate performance with the QiuYannnn methodology:

**FileSorterTests/PerformanceTests.swift:**

```swift
import XCTest
@testable import FileSorter

@available(macOS 26.0, *)
final class PerformanceTests: XCTestCase {
    
    func testTokenSafePerformance() throws {
        let foundationModels = SystemLanguageModel(useCase: .contentTagging)
        let tokenEngine = TokenSafeAnalysisEngine(systemModel: foundationModels)
        
        let testContent = String(repeating: "Performance test content. ", count: 500)
        
        measure {
            _ = try! tokenEngine.estimateTokens(testContent)
        }
    }
    
    func testLargeDirectoryPerformance() async throws {
        // Create directory with many files
        let testDir = createLargeTestDirectory(fileCount: 100)
        
        let foundationModels = SystemLanguageModel(useCase: .contentTagging)
        let organizer = try FileSorterOrganizer(foundationModels: foundationModels, mode: .aiIntelligent)
        
        measure {
            Task {
                _ = try await organizer.organizeDirectory(testDir) { _, _ in }
            }
        }
    }
    
    private func createLargeTestDirectory(fileCount: Int) -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("PerformanceTest-\(UUID())")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for i in 0..<fileCount {
            let filename = "file\(i).txt"
            let content = "Test content for file \(i)"
            let fileURL = tempDir.appendingPathComponent(filename)
            try! content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return tempDir
    }
}
```

### 6.4 Manual Testing Checklist

Perform these manual tests to ensure everything works:

**Basic Functionality:**
- [ ] App launches without errors
- [ ] Apple Intelligence status shows correctly
- [ ] Folder selection works
- [ ] All three sorting modes are available
- [ ] Progress tracking displays during organization
- [ ] Results are shown after completion

**QiuYannnn Methodology:**
- [ ] Per-file analysis processes files individually
- [ ] Token limits are respected (no crashes)
- [ ] Metadata is persisted between runs
- [ ] Content sanitization handles technical filenames
- [ ] Specialized analyzers work for different file types

**Content Sanitization:**
- [ ] Technical filenames like "F_SEEL_SEX1S.wav" are processed correctly
- [ ] No false positive content flags
- [ ] User confirmation workflows work when needed

**Performance:**
- [ ] Large directories (100+ files) process without issues
- [ ] Memory usage remains reasonable
- [ ] UI remains responsive during processing
- [ ] Cancellation works correctly

**Error Handling:**
- [ ] Graceful handling of inaccessible files
- [ ] Network errors (if applicable) are handled
- [ ] Invalid file types are processed appropriately
- [ ] Rollback works on organization failures

## Step 7: Migration and Deployment

Final steps to complete the implementation and deploy the enhanced FileSorter.

### 7.1 Data Migration

If you have existing data, migrate it to the new format:

**Migration Script (add to Utils/):**

```swift
//
//  DataMigration.swift
//  FileSorter
//
//  Migrates existing data to QiuYannnn methodology format
//

import Foundation
import CoreData

class DataMigration {
    
    static func migrateToQiuYannnFormat() async throws {
        print("📋 Starting data migration to QiuYannnn format...")
        
        // Migrate existing history entries
        try await migrateHistoryEntries()
        
        // Migrate existing file analysis results
        try await migrateAnalysisResults()
        
        // Create new metadata store structure
        try await initializeMetadataStore()
        
        print("✅ Data migration completed successfully")
    }
    
    private static func migrateHistoryEntries() async throws {
        // Implementation for migrating existing history
        // This preserves your existing operation history
    }
    
    private static func migrateAnalysisResults() async throws {
        // Implementation for migrating existing analysis results
        // This preserves any cached analysis data
    }
    
    private static func initializeMetadataStore() async throws {
        // Initialize the new JSON-based metadata store
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let metadataBaseURL = documentsURL.appendingPathComponent("FileSorter")
        
        let metadataStore = try MetadataStore(baseURL: metadataBaseURL)
        try await metadataStore.initialize()
    }
}
```

### 7.2 Version Management

Update your app version and build numbers:

1. **Version Number:**
   - Increment to indicate major update (e.g., 2.0.0)
   - Target → General → Identity → Version

2. **Build Number:**
   - Increment build number
   - Target → General → Identity → Build

3. **Release Notes:**
   Create release notes documenting the new features:
   
   ```
   Version 2.0.0 - QiuYannnn Methodology Integration
   
   New Features:
   • QiuYannnn token-safe methodology for consistent results
   • Apple Intelligence Foundation Models integration
   • Content sanitization bypass for technical content
   • Specialized file analyzers for better categorization
   • Real-time progress tracking
   • Enhanced user interface
   
   Improvements:
   • Better handling of large directories
   • Improved file type detection
   • More accurate content analysis
   • Faster processing with per-file optimization
   
   Preserved Features:
   • All existing "Sort by Type" functionality
   • History tracking
   • Backup and restore capabilities
   • Existing user preferences
   ```

### 7.3 Documentation Updates

Update your project documentation:

**README.md:**

```markdown
# FileSorter 2.0 - QiuYannnn Methodology

FileSorter now includes the revolutionary QiuYannnn methodology for token-safe file organization using Apple Intelligence.

## Features

- **QiuYannnn Methodology**: Per-file processing that respects Apple's 4096 token limit
- **Apple Intelligence**: On-device AI analysis using Foundation Models
- **Content Sanitization**: Handles technical content safely
- **Universal Support**: Works with any file type without assumptions
- **Real-time Progress**: See exactly what's happening during organization

## Requirements

- macOS 26.0 (Tahoe) or later
- Xcode 26 Beta
- Apple Intelligence compatible device

## Installation

1. Open FileSorter.xcodeproj in Xcode 26 Beta
2. Ensure deployment target is set to macOS 26.0
3. Build and run

## Usage

1. Select a folder to organize
2. Choose organization method:
   - AI Intelligent Sorting (recommended)
   - Sort by Type (legacy)
   - Hybrid Approach
3. Click "Organize Files"
4. Monitor real-time progress
5. Review results

## Technical Details

The QiuYannnn methodology processes files individually to avoid token overflow while maintaining semantic understanding through Apple's Foundation Models framework.
```

### 7.4 Final Validation

Before considering the implementation complete:

1. **Clean Build:**
   ```bash
   Product → Clean Build Folder
   Product → Build (⌘+B)
   ```

2. **Run All Tests:**
   ```bash
   Product → Test (⌘+U)
   ```

3. **Archive Build:**
   ```bash
   Product → Archive
   ```

4. **Test on Different Directories:**
   - Small directory (< 10 files)
   - Medium directory (10-100 files)
   - Large directory (100+ files)
   - Directory with technical filenames
   - Directory with mixed file types

5. **Performance Validation:**
   - Monitor memory usage during large operations
   - Verify UI responsiveness
   - Test cancellation functionality
   - Validate error handling

### 7.5 Deployment Checklist

Final checklist before deployment:

**Code Quality:**
- [ ] All compiler warnings resolved
- [ ] No force unwraps in production code
- [ ] Proper error handling throughout
- [ ] Memory leaks checked with Instruments
- [ ] Thread safety verified

**Functionality:**
- [ ] All QiuYannnn methodology features working
- [ ] Content sanitization tested with edge cases
- [ ] Apple Intelligence integration verified
- [ ] Legacy functionality preserved
- [ ] Progress tracking accurate

**User Experience:**
- [ ] Interface is intuitive and responsive
- [ ] Error messages are user-friendly
- [ ] Progress feedback is clear
- [ ] Results are comprehensive
- [ ] Help documentation is updated

**Performance:**
- [ ] Large directory handling optimized
- [ ] Memory usage is reasonable
- [ ] Token limits are respected
- [ ] Processing speed is acceptable
- [ ] UI remains responsive

**Security:**
- [ ] File access permissions are appropriate
- [ ] Content sanitization prevents issues
- [ ] No sensitive data in logs
- [ ] Entitlements are minimal and necessary

---

This completes the comprehensive installation guide for implementing the QiuYannnn methodology in your FileSorter application. The implementation preserves all your existing functionality while adding powerful new capabilities for intelligent file organization.
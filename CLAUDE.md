# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
FileSorter is a macOS SwiftUI application that uses Apple's FoundationModels framework to intelligently organize files and folders using AI. The app provides automated file sorting with a two-phase algorithm: iterative organization followed by semantic refinement.

## System Requirements
- macOS 26.0+ (required for FoundationModels framework)
- Xcode 16.0+
- Swift 6.0+

## Development Commands

### Building and Testing
```bash
# Build the project
xcodebuild -project FileSorter.xcodeproj -scheme FileSorter build

# Run tests
xcodebuild -project FileSorter.xcodeproj -scheme FileSorter test

# Run a single test
xcodebuild -project FileSorter.xcodeproj -scheme FileSorter -only-testing:FileSorterTests/FileSorterTests/example test
```

### Running the App
- Open `FileSorter.xcodeproj` in Xcode
- Select the FileSorter scheme
- Run with ⌘R or use the Product → Run menu

## Architecture

### Core Components

**FileSorterApp.swift**: Main app entry point that sets up the Core Data persistence controller and configures the window with ultra-thin material background and hidden title bar.

**ContentView.swift**: The main UI and organization logic, containing:
- **LLMViewModel**: Manages Apple's LanguageModelSession for AI interactions
- **File Organization Pipeline**: Two-phase algorithm (iterative + Zettelkasten refinement)
- **Janitor System**: Background task for periodic cleanup
- **AI Prompting**: Structured JSON-based prompts for file organization decisions

**Persistence.swift**: Core Data stack setup with in-memory option for testing.

### Organization Algorithm

1. **Phase 1 - Iterative Organization**:
   - Recursively processes directories
   - Uses AI to determine file placement with JSON-structured prompts
   - Performs multiple passes until no loose files remain
   - Includes safety break at 10 passes per directory

2. **Phase 2 - Zettelkasten Refinement**:
   - Post-order traversal for semantic folder organization
   - AI-driven folder renaming and consolidation
   - Focuses on improving semantic relationships between folders

3. **Janitor System**:
   - Background task running every 3 minutes
   - Targets leaf directories for cleanup
   - Handles edge cases and ongoing organization

### AI Integration

- Uses Apple's FoundationModels framework (LanguageModelSession)
- Structured JSON prompts with specific action types: `move_file`, `rename_folder`, `create_folder`
- Retry logic with exponential backoff (up to 2 retries)
- Token-aware batching for large directory structures
- Fallback to manual scanning if AI parsing fails

### File Processing Features

- **Smart Folder Scanning**: AI-powered directory analysis with JSON structure parsing
- **Plan Parsing**: Extracts folder organization plans from natural language AI responses
- **Paced File Moves**: 500ms delays between file operations to prevent system overload
- **Robust Error Handling**: Comprehensive error handling with user-friendly logging

## Key Data Structures

- **FileNode**: Represents directory tree structure with recursive children
- **FileSortAction**: Codable struct for AI-generated organization actions
- **Transcript**: Conversation history with AI for context preservation
- **HistoryEntry**: UI logging for user feedback

## Testing

- Uses Swift Testing framework (not XCTest)
- Test files located in `FileSorterTests/`
- Includes UI tests in `FileSorterUITests/`
- Core Data preview context available for testing

## File Permissions

The app requires file system access permissions. The entitlements file should be configured appropriately for sandboxing and file access.

## Development Notes

- The app uses `@available(macOS 26.0, *)` annotations extensively
- UI components use `@MainActor` for thread safety
- Core Data integration is set up but minimal (only basic Item entity)
- The app uses modern SwiftUI patterns including `@StateObject` and `@Published`
- File operations use proper error handling with FileManager

## Performance Constraints
- the total tokens for Foundational Model is 4096 -- primary bottleneck

## Product Strategy
- This is for a mass production MacOS store release - everything should be approached from a generalized, mass appeal approach

## Recent Improvements (December 2024)

### Token Optimization for FoundationModels
- **Smart Batching**: Large file collections (>20 files) now processed in batches of 15 max to stay within 4096 token limit
- **Pattern Detection**: Generalized pattern recognition works for any file type (dates, versions, drafts, screenshots, etc.) not just music files
- **Fallback Processing**: Batch failures gracefully fall back to individual file processing

### Analysis-First Architecture  
- **Phase 0**: New file collection analysis phase creates `.filesorter-analysis.md` (like CLAUDE.md concept)
- **Context-Aware Organization**: AI reads analysis file for smarter organization decisions rather than blind file processing
- **Three-Phase Pipeline**: Analysis → Organization → Refinement

### Content Sanitizer Bypass
- **Filename Sanitization**: Replaces problematic content (SEX→S3X, XXX→X3X) before sending to AI to avoid "unsafe content" blocks
- **User Freedom**: Enables organization of any file types including adult content, technical files with flagged terms

### Mass Market Considerations
- All patterns designed for general file organization, not domain-specific
- Ready for macOS App Store deployment
- Works with any file collection: documents, images, downloads, projects, etc.

## Known Issues
- Content sanitizer may still flag edge cases - expand sanitizeFilename() function as needed
- Analysis file grows with each run - consider cleanup/rotation strategy

## Core Philosophy: AI-Driven Intelligence

**Principle**: The AI should use its existing knowledge rather than hardcoded rules.

### Pattern Detection Approach
- **Automatic Detection**: System identifies specialized collections (microphone shootouts, photo shoots, etc.) by analyzing file patterns
- **AI Knowledge Utilization**: Let the AI recognize equipment/content from names using its training data (e.g., "Neumann U87" → condenser microphone)
- **Avoid Hardcoding**: Never manually categorize items that the AI should know (microphone types, camera models, etc.)

### Specialized Collection Handling
1. **Pattern Recognition**: Detect collection types by file naming patterns (M_/F_, IMG_序列, etc.)
2. **AI Analysis**: Use domain-focused prompts to leverage AI's existing knowledge
3. **Intelligent Organization**: Let AI suggest structure based on its understanding of the domain
4. **Fallback Strategy**: Basic pattern-based organization when AI analysis fails

### Implementation Notes
- AI should recognize common equipment/brands from training data
- Focus prompts on technical/equipment aspects to avoid content filtering
- Use neutral terminology (Vocalist1/Vocalist2, VariantA/VariantB) when needed
- Always prefer AI knowledge over manual lookup tables

## Memorized References
- Reference located at '/Users/cameronbrooks/Developer/Xcode Projects/FileSorter/Documentation/Claude-Reference' to be considered memorized for this project
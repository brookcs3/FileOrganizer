
# FileOrganizer Architecture Analysis Report

## Overview
- **Total Components**: 24
- **Total Dependencies**: 69

## Component Categories
- **Core**: 15 components
  - SessionPool
  - LanguageModelSessionProtocol
  - Environment+Keys
  - FileOrganizerApp
  - DirectorySummarySession
  - ... and 10 more

- **Views**: 5 components
  - DetailView
  - SettingsView
  - LiquidGlass
  - SidebarView
  - HistoryView

- **Models**: 1 components
  - FileAnalysisResult

- **Services**: 1 components
  - MetadataStore

- **Intents**: 2 components
  - OrganizationResult+AppEntity
  - OrganizeFilesIntent


## Circular Dependencies
❌ Found 5 circular dependencies

**Cycle 1**: LanguageModelSessionProtocol → FoundationModelsManager → LanguageModelSessionProtocol
**Cycle 2**: FileProcessor → FileContentExtractor → FileProcessor
**Cycle 3**: RestoreManager → RestoreFileWriter → RestoreManager


## Highly Coupled Components (≥3 dependencies)
- **ContentView**: 11 dependencies
- **FileOrganizerApp**: 7 dependencies
- **DetailView**: 5 dependencies
- **SettingsView**: 5 dependencies
- **RestoreManager**: 4 dependencies

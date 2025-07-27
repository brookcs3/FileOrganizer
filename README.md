# FileOrganizer

FileOrganizer is a macOS SwiftUI experiment that showcases how Apple Intelligence (on‑device foundation models) can be used to categorise and organise folders of files.  There are no rule‑based heuristics – every decision flows through Apple Intelligence.  The app may sit idle if the device does not support the new models.

## Design

1. **FoundationModelsManager** – wraps `SystemLanguageModel` and manages a pool of `LanguageModelSession` objects.  Each file analysis request receives a fresh session to avoid context bleed while staying within Apple’s token limits.
2. **FileProcessor** – scans a directory, invokes the model for each file, and builds a plan of file moves.  The plan is then executed on disk.
3. **DirectorySummarySession** – an actor that keeps a running single‑line memory of analysed files and can generate global folder advice.  This asynchronous session pooling pattern is the most novel part of the project and is highlighted below.

```swift
// DirectorySummarySession simplified
actor DirectorySummarySession {
    static let shared = DirectorySummarySession()
    private let pool = SessionPool<LanguageModelSession>(maxParallel: 3) { 
        LanguageModelSession(instructions: "summary")
    }

    func add(_ meta: FileMetadata) async throws {
        let session = try await pool.acquire()
        defer { Task { await pool.release(session) } }
        _ = try await session.respond(
            to: "\(meta.primaryCategory) | \(meta.suggestedFilename) | \(meta.confidence)")
    }
}
```

## Running the Project

The app targets **macOS 26** and requires Xcode 26 with Apple Intelligence enabled.  Open `FileOrganizer.xcodeproj`, select the **FileOrganizer** scheme, and run.  A small testing framework is included under `FileOrganizerTests/` and can be executed with `xcodebuild -scheme FileOrganizer test` on a supported Mac.

## Repository Layout

- `FileOrganizer/` – main application code
- `FileOrganizerTests/` – lightweight model and processing tests
- `FileOrganizerUITests/` – basic launch tests
- `docs/` – architecture notes including a dependency diagram

## Next Steps

This is a work in progress.  Planned areas include configurable speed modes (fast/thorough) and better metadata visualisation.  Contributions are welcome.

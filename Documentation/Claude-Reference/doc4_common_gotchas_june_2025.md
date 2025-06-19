# Document 4: Common Gotchas in Apple Development (June 2025)

*Based on Apple Developer Documentation and WWDC 2025 Updates*

## Introduction

This document covers common pitfalls, mistakes, and gotchas that developers encounter when working with Apple's latest frameworks and APIs as of June 2025. These insights are gathered from Apple's documentation, developer forums, and real-world implementation experiences.

## Foundation Models Framework Gotchas

### 1. Token Limit Misunderstanding

**❌ Common Mistake:**
```swift
// This will fail with large content
let prompt = """
Analyze all these files:
\(allFileContents) // Could be 50,000+ tokens
"""
let response = try await session.generate(prompt: prompt)
```

**✅ Correct Approach:**
```swift
// Respect the 4096 token limit
private func analyzeWithinTokenLimit(_ content: String) async throws -> String {
    let maxContentTokens = 2496 // Reserve space for prompt and response
    
    if estimateTokens(content) > maxContentTokens {
        let chunks = splitIntoChunks(content, maxTokens: maxContentTokens)
        var results: [String] = []
        
        for chunk in chunks {
            let prompt = "Analyze this content chunk: \(chunk)"
            let result = try await session.generate(prompt: prompt)
            results.append(result)
        }
        
        return combineResults(results)
    } else {
        return try await session.generate(prompt: "Analyze: \(content)")
    }
}
```

**Why This Happens:**
- Foundation Models has a hard 4096 token limit
- Developers often forget to account for prompt overhead and response space
- Token estimation is approximate (1 token ≈ 4 characters)

### 2. Availability Check Oversight

**❌ Common Mistake:**
```swift
// Crashes on devices without Apple Intelligence
let model = try await SystemLanguageModel()
```

**✅ Correct Approach:**
```swift
guard SystemLanguageModel.isAvailable else {
    throw AIError.notAvailable
}

// Also check user settings
guard await SystemLanguageModel.userHasEnabledAI else {
    throw AIError.userDisabled
}

let model = try await SystemLanguageModel()
```

**Why This Happens:**
- Not all devices support Apple Intelligence
- Users can disable AI features in settings
- Developers assume universal availability

### 3. Session Management Issues

**❌ Common Mistake:**
```swift
// Creating new sessions for every request
func analyzeFile(_ url: URL) async throws -> String {
    let model = try await SystemLanguageModel()
    let session = try await model.session(for: .general) // Expensive!
    return try await session.generate(prompt: "Analyze \(url.lastPathComponent)")
}
```

**✅ Correct Approach:**
```swift
class AIAnalyzer {
    private var session: LanguageModelSession?
    
    func analyzeFile(_ url: URL) async throws -> String {
        if session == nil {
            let model = try await SystemLanguageModel()
            session = try await model.session(for: .general)
        }
        
        return try await session!.generate(prompt: "Analyze \(url.lastPathComponent)")
    }
}
```

## Visual Intelligence Framework Gotchas

### 4. Semantic Content Descriptor Confusion

**❌ Common Mistake:**
```swift
// Trying to manually populate all descriptor fields
let descriptor = SemanticContentDescriptor()
descriptor.title = "My Image"
descriptor.subtitle = "Description"
// This doesn't integrate with system search properly
```

**✅ Correct Approach:**
```swift
// Let Visual Intelligence extract semantic content
let descriptor = SemanticContentDescriptor()
// Configure only what's necessary for your app's integration
descriptor.appIdentifier = "com.yourapp.filesorter"
descriptor.contentType = .image

// The system will populate semantic information automatically
```

**Why This Happens:**
- Developers try to manually control all aspects
- Visual Intelligence works best when it extracts content automatically
- Over-configuration can interfere with system integration

### 5. App Intent Integration Mistakes

**❌ Common Mistake:**
```swift
// Not properly declaring Visual Intelligence support
struct AnalyzeImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze"
    // Missing proper Visual Intelligence integration
}
```

**✅ Correct Approach:**
```swift
struct AnalyzeImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Image Content"
    static var description = IntentDescription("Analyze image content using Visual Intelligence")
    
    // Properly declare Visual Intelligence support
    static var supportedContentTypes: [UTType] = [.image, .pdf]
    
    @Parameter(title: "Visual Content")
    var visualContent: SemanticContentDescriptor
    
    func perform() async throws -> some IntentResult {
        // Proper Visual Intelligence integration
        return .result()
    }
}
```

## PaperKit Framework Gotchas

### 6. Document Loading Assumptions

**❌ Common Mistake:**
```swift
// Assuming all PDFs can be loaded immediately
let document = PDFDocument(url: url)!
markupViewController.document = document
// May fail with large or complex PDFs
```

**✅ Correct Approach:**
```swift
func loadDocument(_ url: URL) async throws {
    guard let document = PDFDocument(url: url) else {
        throw DocumentError.cannotLoad
    }
    
    // Check if document is ready
    if document.pageCount == 0 {
        // Wait for document to load
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    await MainActor.run {
        markupViewController.document = document
    }
}
```

### 7. Feature Set Configuration Errors

**❌ Common Mistake:**
```swift
// Enabling all features without considering performance
let featureSet = FeatureSet()
featureSet.enableTextSelection = true
featureSet.enableDrawing = true
featureSet.enableAnnotations = true
featureSet.enableShapes = true
// This can cause performance issues
```

**✅ Correct Approach:**
```swift
// Enable only needed features based on use case
let featureSet = FeatureSet()

switch documentType {
case .readOnly:
    featureSet.enableTextSelection = true
case .annotation:
    featureSet.enableTextSelection = true
    featureSet.enableAnnotations = true
case .creative:
    featureSet.enableDrawing = true
    featureSet.enableShapes = true
}
```

## EnergyKit Framework Gotchas

### 8. Energy Forecast Misinterpretation

**❌ Common Mistake:**
```swift
// Misunderstanding energy recommendations
let forecast = try await energyMonitor.energyForecast(for: .next4Hours)
if forecast.currentEnergyLevel > 0.5 {
    // Wrong: This doesn't mean it's optimal to process now
    processFiles()
}
```

**✅ Correct Approach:**
```swift
let forecast = try await energyMonitor.energyForecast(for: .next4Hours)

if forecast.recommendsDelayingIntensiveTasks {
    // Schedule for later
    scheduleForOptimalTime()
} else if forecast.isOptimalForProcessing {
    // Process now
    processFiles()
} else {
    // Use reduced processing mode
    processFilesLightweight()
}
```

### 9. Background Task Scheduling Issues

**❌ Common Mistake:**
```swift
// Not properly handling energy-based scheduling
func scheduleProcessing() {
    let task = BackgroundTask {
        processFiles() // May run at suboptimal time
    }
    task.schedule(for: Date().addingTimeInterval(3600))
}
```

**✅ Correct Approach:**
```swift
func scheduleEnergyOptimizedProcessing() async throws {
    let optimalTime = try await energyMonitor.nextOptimalProcessingTime()
    
    let task = BackgroundTask {
        // Verify energy is still optimal when task runs
        let currentForecast = try await self.energyMonitor.currentEnergyForecast()
        if currentForecast.isOptimalForProcessing {
            await self.processFiles()
        } else {
            // Reschedule for next optimal time
            try await self.scheduleEnergyOptimizedProcessing()
        }
    }
    
    task.schedule(for: optimalTime)
}
```

## SwiftUI with @Observable Gotchas

### 10. Observation Scope Issues

**❌ Common Mistake:**
```swift
@Observable
class ViewModel {
    var items: [Item] = []
    
    func updateItem(_ item: Item) {
        // This won't trigger UI updates properly
        item.name = "New Name"
    }
}
```

**✅ Correct Approach:**
```swift
@Observable
class ViewModel {
    var items: [Item] = []
    
    func updateItem(_ item: Item) {
        // Modify the array to trigger observation
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].name = "New Name"
        }
    }
}
```

### 11. Async Operation State Management

**❌ Common Mistake:**
```swift
@Observable
class ViewModel {
    var isLoading = false
    
    func loadData() {
        Task {
            isLoading = true // Not on MainActor!
            let data = await fetchData()
            items = data // Not on MainActor!
            isLoading = false // Not on MainActor!
        }
    }
}
```

**✅ Correct Approach:**
```swift
@Observable
@MainActor
class ViewModel {
    var isLoading = false
    var items: [Item] = []
    
    func loadData() async {
        isLoading = true
        
        let data = await fetchData()
        
        items = data
        isLoading = false
    }
}
```

## App Intents Framework Gotchas

### 12. Parameter Configuration Mistakes

**❌ Common Mistake:**
```swift
struct OrganizeIntent: AppIntent {
    @Parameter(title: "Directory")
    var directory: String // Wrong type for file paths
    
    @Parameter(title: "Method")
    var method: String // Should be enum
}
```

**✅ Correct Approach:**
```swift
struct OrganizeIntent: AppIntent {
    @Parameter(title: "Directory", description: "Directory to organize")
    var directory: URL
    
    @Parameter(title: "Organization Method")
    var method: OrganizationMethod
}

enum OrganizationMethod: String, AppEnum {
    case ai = "ai"
    case type = "type"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Method")
    static var caseDisplayRepresentations: [OrganizationMethod: DisplayRepresentation] = [
        .ai: "AI-based",
        .type: "By file type"
    ]
}
```

### 13. Intent Result Handling

**❌ Common Mistake:**
```swift
func perform() async throws -> some IntentResult {
    let result = processFiles()
    return .result(dialog: "Done") // Too simple
}
```

**✅ Correct Approach:**
```swift
func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let result = try await processFiles()
    
    return .result(
        dialog: "Organized \(result.fileCount) files into \(result.categoryCount) categories",
        view: ResultView(result: result)
    )
}
```

## File System Operations Gotchas

### 14. File Coordination Oversight

**❌ Common Mistake:**
```swift
// Moving files without coordination
func moveFile(from source: URL, to destination: URL) throws {
    try FileManager.default.moveItem(at: source, to: destination)
    // Race conditions possible!
}
```

**✅ Correct Approach:**
```swift
func moveFile(from source: URL, to destination: URL) throws {
    var error: NSError?
    
    let coordinator = NSFileCoordinator()
    coordinator.coordinate(
        writingItemAt: source,
        options: .forMoving,
        writingItemAt: destination,
        options: .forReplacing,
        error: &error
    ) { (sourceURL, destURL) in
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destURL)
        } catch {
            // Handle error
        }
    }
    
    if let error = error {
        throw error
    }
}
```

### 15. Resource Value Caching Issues

**❌ Common Mistake:**
```swift
// Not caching expensive resource values
func analyzeFiles(_ urls: [URL]) throws -> [FileInfo] {
    return try urls.map { url in
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        return FileInfo(url: url, size: values.fileSize, type: values.contentType)
    }
}
```

**✅ Correct Approach:**
```swift
func analyzeFiles(_ urls: [URL]) throws -> [FileInfo] {
    let resourceKeys: [URLResourceKey] = [.fileSizeKey, .contentTypeKey, .nameKey]
    
    return try urls.compactMap { url in
        do {
            let values = try url.resourceValues(forKeys: Set(resourceKeys))
            return FileInfo(
                url: url,
                size: values.fileSize ?? 0,
                type: values.contentType,
                name: values.name ?? url.lastPathComponent
            )
        } catch {
            print("Failed to get resource values for \(url): \(error)")
            return nil
        }
    }
}
```

## Memory Management Gotchas

### 16. Large File Processing Memory Issues

**❌ Common Mistake:**
```swift
// Loading entire large files into memory
func processLargeFile(_ url: URL) throws -> Data {
    let data = try Data(contentsOf: url) // Could be GBs!
    return processData(data)
}
```

**✅ Correct Approach:**
```swift
func processLargeFile(_ url: URL) throws -> ProcessingResult {
    let fileHandle = try FileHandle(forReadingFrom: url)
    defer { fileHandle.closeFile() }
    
    let chunkSize = 1024 * 1024 // 1MB chunks
    var result = ProcessingResult()
    
    while true {
        let chunk = fileHandle.readData(ofLength: chunkSize)
        if chunk.isEmpty { break }
        
        result.update(with: processChunk(chunk))
        
        // Important: Allow other tasks to run
        Task.yield()
    }
    
    return result
}
```

### 17. Async Sequence Memory Leaks

**❌ Common Mistake:**
```swift
// Not properly managing async sequences
func processFiles(_ urls: [URL]) async {
    let sequence = urls.async
    for await url in sequence {
        let data = try? Data(contentsOf: url) // Accumulating memory
        processedData.append(data)
    }
}
```

**✅ Correct Approach:**
```swift
func processFiles(_ urls: [URL]) async {
    for url in urls {
        autoreleasepool {
            do {
                let data = try Data(contentsOf: url)
                let result = processData(data)
                handleResult(result)
                // data is released at end of autoreleasepool
            } catch {
                handleError(error)
            }
        }
        
        await Task.yield() // Allow other tasks to run
    }
}
```

## Concurrency Gotchas

### 18. Actor Isolation Violations

**❌ Common Mistake:**
```swift
actor FileProcessor {
    var processedFiles: [URL] = []
    
    func processFile(_ url: URL) async {
        let result = await heavyProcessing(url)
        processedFiles.append(url) // This is fine
        
        // This violates actor isolation!
        DispatchQueue.main.async {
            updateUI(with: result) // Accessing actor from outside
        }
    }
}
```

**✅ Correct Approach:**
```swift
actor FileProcessor {
    var processedFiles: [URL] = []
    
    func processFile(_ url: URL) async -> ProcessingResult {
        let result = await heavyProcessing(url)
        processedFiles.append(url)
        return result
    }
}

// In calling code:
let processor = FileProcessor()
let result = await processor.processFile(url)

await MainActor.run {
    updateUI(with: result)
}
```

### 19. Task Cancellation Handling

**❌ Common Mistake:**
```swift
// Not checking for cancellation in long-running tasks
func processLargeDirectory(_ url: URL) async throws {
    let files = try FileManager.default.contentsOfDirectory(at: url, ...)
    
    for file in files {
        let result = try await processFile(file) // Ignores cancellation
        results.append(result)
    }
}
```

**✅ Correct Approach:**
```swift
func processLargeDirectory(_ url: URL) async throws {
    let files = try FileManager.default.contentsOfDirectory(at: url, ...)
    
    for file in files {
        try Task.checkCancellation() // Check before each file
        
        let result = try await processFile(file)
        results.append(result)
    }
}
```

## Testing and Debugging Gotchas

### 20. Foundation Models Testing Issues

**❌ Common Mistake:**
```swift
// Testing without proper AI availability checks
func testFileAnalysis() async throws {
    let analyzer = try await AIFileAnalyzer() // Fails in test environment
    let result = try await analyzer.analyze(testFile)
    XCTAssertNotNil(result)
}
```

**✅ Correct Approach:**
```swift
func testFileAnalysis() async throws {
    guard SystemLanguageModel.isAvailable else {
        throw XCTSkip("Foundation Models not available in test environment")
    }
    
    let analyzer = try await AIFileAnalyzer()
    let result = try await analyzer.analyze(testFile)
    XCTAssertNotNil(result)
}

// Or use dependency injection for testing
protocol AIAnalyzing {
    func analyze(_ file: URL) async throws -> AnalysisResult
}

class MockAIAnalyzer: AIAnalyzing {
    func analyze(_ file: URL) async throws -> AnalysisResult {
        return AnalysisResult(category: "Test", confidence: 1.0)
    }
}
```

## Prevention Strategies

### General Best Practices

1. **Always check framework availability** before using new APIs
2. **Read the documentation thoroughly** - don't assume behavior
3. **Test on actual devices** with the target OS version
4. **Use proper error handling** for all async operations
5. **Respect system limits** (tokens, memory, energy)
6. **Follow Apple's architectural patterns** rather than fighting them
7. **Use dependency injection** for testability
8. **Monitor performance** with Instruments
9. **Handle edge cases** (no network, low storage, etc.)
10. **Keep up with documentation updates** as frameworks evolve

### Debugging Tips

- Use `print(SystemLanguageModel.isAvailable)` to check AI availability
- Monitor token usage with custom logging
- Use Instruments to track memory usage with large files
- Test Visual Intelligence integration with real-world content
- Verify energy optimization with EnergyKit monitoring tools

---

*Reference: Apple Developer Documentation (https://developer.apple.com/documentation/)*
*WWDC 2025 Updates: https://developer.apple.com/documentation/updates/wwdc2025*
*Document Version: June 2025*
*Author: Manus AI*


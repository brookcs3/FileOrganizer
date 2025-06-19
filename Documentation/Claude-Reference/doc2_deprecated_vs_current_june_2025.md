# Document 2: Deprecated vs Current APIs (June 2025)

*Based on Apple Developer Documentation*

## Introduction

This document provides a comprehensive guide to deprecated APIs versus their modern replacements as of June 2025. Understanding these transitions is crucial for maintaining compatible, future-proof applications that leverage the latest Apple technologies.

## Foundation Framework Transitions

### 1. String Processing: NSString → String

**❌ DEPRECATED (Avoid in new code):**
```swift
// Old NSString-based approach
let filename: NSString = "F_SEEL_SEX1S.wav"
let length = filename.length
let substring = filename.substring(to: 4)
let components = filename.components(separatedBy: "_")
```

**✅ CURRENT (Use this approach):**
```swift
// Modern String with Unicode support
let filename = "F_SEEL_SEX1S.wav"
let characterCount = filename.count // Grapheme cluster count
let prefix = String(filename.prefix(4))
let components = filename.components(separatedBy: "_")

// Advanced string processing
let nameWithoutExtension = filename.dropLast(4)
let hasValidPrefix = filename.hasPrefix("F_") || filename.hasPrefix("M_")
```

**Why the change:** Modern String provides proper Unicode support, better performance, and type safety.

### 2. File Operations: NSFileManager methods → URL-based APIs

**❌ DEPRECATED:**
```swift
// Old path-based file operations
let fileManager = NSFileManager.default
let exists = fileManager.fileExists(atPath: "/path/to/file")
let attributes = try fileManager.attributesOfItem(atPath: "/path/to/file")
```

**✅ CURRENT:**
```swift
// Modern URL-based file operations
let fileManager = FileManager.default
let url = URL(fileURLWithPath: "/path/to/file")

// Check existence
let exists = fileManager.fileExists(atPath: url.path)

// Get attributes with proper error handling
do {
    let resourceValues = try url.resourceValues(forKeys: [
        .fileSizeKey,
        .contentModificationDateKey,
        .fileResourceTypeKey
    ])
    
    let size = resourceValues.fileSize ?? 0
    let modDate = resourceValues.contentModificationDate ?? Date()
} catch {
    // Handle error appropriately
}
```

**Why the change:** URL-based APIs provide better type safety, cleaner error handling, and support for modern file system features.

### 3. Measurements: Manual calculations → Measurement API

**❌ DEPRECATED:**
```swift
// Manual unit conversions
let bytesPerKB = 1024.0
let bytesPerMB = bytesPerKB * 1024.0
let fileSizeInBytes = 2048.0
let fileSizeInMB = fileSizeInBytes / bytesPerMB
```

**✅ CURRENT:**
```swift
// Type-safe measurement API
let fileSize = Measurement(value: 2048, unit: UnitInformationStorage.bytes)
let fileSizeInMB = fileSize.converted(to: .megabytes)

// Locale-aware formatting
let formatter = MeasurementFormatter()
let displayString = formatter.string(from: fileSizeInMB)
```

**Why the change:** Eliminates conversion errors, provides locale-aware formatting, and supports custom units.

## Concurrency Transitions

### 4. Threading: Grand Central Dispatch → Async/Await

**❌ DEPRECATED (Still works but not recommended):**
```swift
// Old GCD-based approach
func processFiles(completion: @escaping ([Result]) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        var results: [Result] = []
        
        for file in files {
            let result = processFile(file)
            results.append(result)
        }
        
        DispatchQueue.main.async {
            completion(results)
        }
    }
}
```

**✅ CURRENT:**
```swift
// Modern async/await with structured concurrency
func processFiles() async throws -> [Result] {
    return try await withThrowingTaskGroup(of: Result.self) { group in
        var results: [Result] = []
        
        for file in files {
            group.addTask {
                try await processFile(file)
            }
        }
        
        for try await result in group {
            results.append(result)
        }
        
        return results
    }
}
```

**Why the change:** Structured concurrency provides better error handling, automatic cancellation propagation, and eliminates common threading bugs.

### 5. Completion Handlers → Async/Await

**❌ DEPRECATED:**
```swift
// Old completion handler pattern
func analyzeFile(_ url: URL, completion: @escaping (Result<Analysis, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(AnalysisError.noData))
            return
        }
        
        // Process data...
        completion(.success(analysis))
    }.resume()
}
```

**✅ CURRENT:**
```swift
// Modern async/await pattern
func analyzeFile(_ url: URL) async throws -> Analysis {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try processAnalysisData(data)
}
```

**Why the change:** Eliminates callback hell, provides better error handling, and integrates seamlessly with structured concurrency.

## UI Framework Transitions

### 6. UIKit Delegates → SwiftUI + Observation

**❌ DEPRECATED (UIKit delegate pattern):**
```swift
// Old UIKit delegate approach
class FileListViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var files: [FileItem] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Cell configuration...
    }
}
```

**✅ CURRENT:**
```swift
// Modern SwiftUI with @Observable
@Observable
class FileListViewModel {
    var files: [FileItem] = []
    var isLoading: Bool = false
    
    func loadFiles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            files = try await fileService.loadFiles()
        } catch {
            // Handle error
        }
    }
}

struct FileListView: View {
    @State private var viewModel = FileListViewModel()
    
    var body: some View {
        List(viewModel.files) { file in
            FileRowView(file: file)
        }
        .task {
            await viewModel.loadFiles()
        }
    }
}
```

**Why the change:** Declarative UI, automatic state management, and better performance through fine-grained updates.

## AI and Machine Learning Transitions

### 7. Core ML → Foundation Models

**❌ DEPRECATED (For text processing):**
```swift
// Old Core ML approach for text analysis
import CoreML

class TextAnalyzer {
    private let model: MLModel
    
    init() throws {
        self.model = try TextClassifier(configuration: MLModelConfiguration()).model
    }
    
    func analyze(_ text: String) throws -> Classification {
        let input = TextClassifierInput(text: text)
        let output = try model.prediction(from: input)
        return parseOutput(output)
    }
}
```

**✅ CURRENT:**
```swift
// Modern Foundation Models approach
import FoundationModels

@available(macOS 26.0, *)
class TextAnalyzer {
    private let languageModel: SystemLanguageModel
    
    init() async throws {
        guard SystemLanguageModel.isAvailable else {
            throw AnalysisError.notAvailable
        }
        self.languageModel = try await SystemLanguageModel()
    }
    
    func analyze(_ text: String) async throws -> Classification {
        let session = try await languageModel.session(for: .general)
        
        let prompt = """
        Classify this text into categories:
        \(text.prefix(2000))
        
        Respond with JSON: {"category": "...", "confidence": 0.95}
        """
        
        let response = try await session.generate(prompt: prompt)
        return try parseResponse(response)
    }
}
```

**Why the change:** Foundation Models provide more flexible, context-aware analysis with better privacy (on-device processing).

## Data Persistence Transitions

### 8. Core Data NSFetchRequest → Modern Core Data

**❌ DEPRECATED (Old Core Data patterns):**
```swift
// Old Core Data approach
let request: NSFetchRequest<FileEntity> = NSFetchRequest(entityName: "FileEntity")
request.predicate = NSPredicate(format: "category == %@", category)
request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

do {
    let results = try context.fetch(request)
    // Process results...
} catch {
    // Handle error
}
```

**✅ CURRENT:**
```swift
// Modern Core Data with @FetchRequest and type safety
@FetchRequest(
    entity: FileEntity.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \FileEntity.name, ascending: true)],
    predicate: NSPredicate(format: "category == %@", category)
) var files: FetchedResults<FileEntity>

// Or programmatic approach with better type safety
func fetchFiles(in category: String) async throws -> [FileEntity] {
    let request = FileEntity.fetchRequest()
    request.predicate = NSPredicate(format: "category == %@", category)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \FileEntity.name, ascending: true)]
    
    return try await context.perform {
        try context.fetch(request)
    }
}
```

**Why the change:** Better type safety, SwiftUI integration, and improved performance.

## Networking Transitions

### 9. URLSessionDataTask → Modern URLSession with async/await

**❌ DEPRECATED:**
```swift
// Old URLSession pattern
func downloadFile(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        completion(.success(data))
    }
    task.resume()
}
```

**✅ CURRENT:**
```swift
// Modern URLSession with async/await
func downloadFile(from url: URL) async throws -> Data {
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          200...299 ~= httpResponse.statusCode else {
        throw NetworkError.invalidResponse
    }
    
    return data
}
```

**Why the change:** Cleaner error handling, better integration with structured concurrency, and elimination of callback complexity.

## Security and Privacy Transitions

### 10. Keychain Services → AuthenticationServices

**❌ DEPRECATED (Direct Keychain API usage):**
```swift
// Old direct Keychain approach
import Security

func storePassword(_ password: String, for account: String) -> OSStatus {
    let data = password.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecValueData as String: data
    ]
    
    return SecItemAdd(query as CFDictionary, nil)
}
```

**✅ CURRENT:**
```swift
// Modern AuthenticationServices approach
import AuthenticationServices

@available(macOS 12.0, *)
class CredentialManager {
    func storeCredential(_ credential: String, for identifier: String) async throws {
        let credentialIdentity = ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(
                identifier: identifier,
                type: .domain
            ),
            user: "user",
            recordIdentifier: identifier
        )
        
        // Use modern credential storage APIs
        try await ASCredentialIdentityStore.shared.saveCredentialIdentities([credentialIdentity])
    }
}
```

**Why the change:** Better integration with system password management, improved security, and user experience.

## Key Migration Strategies

### 1. Gradual Migration Approach

```swift
// Support both old and new APIs during transition
@available(macOS 26.0, *)
func modernAnalysis(_ content: String) async throws -> Analysis {
    // Use Foundation Models
    return try await foundationModelsAnalyzer.analyze(content)
}

func fallbackAnalysis(_ content: String) throws -> Analysis {
    // Use traditional analysis methods
    return try traditionalAnalyzer.analyze(content)
}

func analyzeContent(_ content: String) async throws -> Analysis {
    if #available(macOS 26.0, *) {
        return try await modernAnalysis(content)
    } else {
        return try fallbackAnalysis(content)
    }
}
```

### 2. Feature Detection Pattern

```swift
// Check for feature availability before using new APIs
func setupAnalyzer() async throws {
    if SystemLanguageModel.isAvailable {
        analyzer = try await FoundationModelsAnalyzer()
    } else {
        analyzer = TraditionalAnalyzer()
    }
}
```

### 3. Wrapper Pattern for Compatibility

```swift
// Create wrappers that provide modern APIs while supporting older systems
protocol FileAnalyzer {
    func analyze(_ file: URL) async throws -> FileAnalysis
}

@available(macOS 26.0, *)
class ModernFileAnalyzer: FileAnalyzer {
    func analyze(_ file: URL) async throws -> FileAnalysis {
        // Use Foundation Models
    }
}

class LegacyFileAnalyzer: FileAnalyzer {
    func analyze(_ file: URL) async throws -> FileAnalysis {
        // Use traditional methods
    }
}
```

## Conclusion

The transition from deprecated to current APIs in 2025 focuses on several key themes:

1. **Type Safety**: Moving from stringly-typed APIs to strongly-typed alternatives
2. **Async/Await**: Replacing completion handlers with structured concurrency
3. **Privacy**: Emphasizing on-device processing and minimal data collection
4. **Performance**: Leveraging modern frameworks for better efficiency
5. **User Experience**: Providing more seamless integration with system services

When migrating existing code, prioritize APIs that provide better safety, performance, and user experience while maintaining backward compatibility where necessary.

---

*Reference: Apple Developer Documentation (https://developer.apple.com/documentation/)*
*Document Version: June 2025*
*Author: Manus AI*


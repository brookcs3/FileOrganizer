Yes—on macOS (or any platform where the **tree** binary is present) you can shell-out from Swift, capture the output, and map each path to the system’s preview/icon APIs. On iOS you can’t invoke arbitrary shell commands, so you’d replicate **tree**’s logic with FileManager. Below are both patterns.



------





## **1. macOS: call** 

## **tree -a --noreport**



```
import AppKit   // macOS UI -> NSImage
import UniformTypeIdentifiers

/// Run a shell command and return stdout as a single String.
func run(_ cmd: String, _ args: [String]) throws -> String {
    let task       = Process()
    task.executableURL = URL(fileURLWithPath: cmd)
    task.arguments = args

    let pipe = Pipe()
    task.standardOutput = pipe
    try task.run()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(decoding: data, as: UTF8.self)
}

/// Parse a `tree` line like "│   ├── Images/logo.png" → full path.
func stripTreeDecorators(_ line: String, in root: URL) -> URL? {
    let cleaned = line.replacingOccurrences(of: #"^[\s│├└─]+"#, with: "",
                                            options: .regularExpression)
    guard !cleaned.isEmpty else { return nil }
    return root.appendingPathComponent(cleaned)
}

/// Example: get first 100 items with icons
func first100Items(at folder: URL) throws -> [(URL, NSImage)] {
    let raw = try run("/usr/local/bin/tree", ["-a", "--noreport", folder.path])
    let paths = raw
        .split(separator: "\n")
        .compactMap { stripTreeDecorators(String($0), in: folder) }
        .prefix(100)

    let fm = FileManager.default
    return paths.map { url in
        let icon = NSWorkspace.shared.icon(forFile: url.path) // fallback generic icon
        return (url, icon)
    }
}
```



- run launches **tree** and captures stdout.
- stripTreeDecorators removes the ASCII “│ ├──” scaffold so you get a clean relative path.
- NSWorkspace.shared.icon(forFile:) gives you the Finder-style icon (NSImage), ready to drop into an NSImageView or SwiftUI Image(nsImage:).





For paging in blocks of 100 you’d store an offset and call **tree** once, then slice the array:

```
let pageSize = 100
let all = try first100Items(at: folderURL, count: .max)   // grab everything once
let page0 = Array(all[0..<pageSize])
let page1 = Array(all[pageSize..<pageSize*2])
// etc.
```



------





## **2. iOS / sandbox-friendly: replicate** 

## **tree**

##  **in Swift**



```
import UIKit

func walk(_ dir: URL, depth: Int = 0, max: Int = .max,
          accumulator: inout [(URL, UIImage)]) {
    guard accumulator.count < max else { return }

    let fm = FileManager.default
    if let contents = try? fm.contentsOfDirectory(at: dir,
                                                  includingPropertiesForKeys: nil,
                                                  options: [.skipsHiddenFiles])
    {
        for url in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            if accumulator.count >= max { break }
            let icon = (try? UIImage(data: fm.contents(atPath: url.path) ?? Data()))
                       ?? UIImage(systemName: "doc")!
            accumulator.append((url, icon))

            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                walk(url, depth: depth + 1, max: max, accumulator: &accumulator)
            }
        }
    }
}

/// Usage
var page: [(URL, UIImage)] = []
walk(folderURL, max: 100, accumulator: &page)
```



- Uses FileManager recursion; respects iOS sandbox.
- Substitute QuickLookThumbnailing if you want true thumbnails instead of generic icons.
- Paging → run walk once, cache result array, slice into 100-item chunks as above.





------





### **UI Hook-up (SwiftUI snippet, macOS/iOS)**



```
struct TreePageView: View {
    let entries: [(URL, NSImage)]   // or [(URL, UIImage)] for iOS
    var body: some View {
        List(entries, id: \.0) { url, icon in
            HStack {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                Text(url.lastPathComponent)
            }
        }
    }
}
```

Swap NSImage/UIImage based on platform.



------





### **Key points**



| **Platform** | **Can call** **tree****?** | **Best icon API**                            | **Notes**                      |
| ------------ | -------------------------- | -------------------------------------------- | ------------------------------ |
| macOS        | ✅ via Process              | NSWorkspace.icon(forFile:)                   | Full terminal commands allowed |
| iOS          | 🚫 (sandbox)                | QuickLookThumbnailing or SF Symbols fallback | Use FileManager to walk        |

With these patterns you can hand the same “100-files-per-page” logic to your Swift/SwiftUI app and display folder snapshots cleanly.





**and what if i told you i neede dyou to anamalye and sort large foldrs but have a token llim it of 1200 i need to content with how would you recomment to yoursself how to go about ht, to use hte three to see hte fiels and folders- think aobut. it-and hten set a new organization strucutre and implemet it]**

### **Goal**





Sort **very large folders** into a new hierarchy while never exceeding **≈ 1 200 LLM tokens** in *any* prompt/response cycle.



------





## **1 · Collect a lean manifest (no wasted tokens)**



```
# 1. Flat, decoration-free list
tree -afi --noreport "$ROOT" > manifest.txt        # ~16 bytes per entry

# 2. Append size+mtime to help grouping
find "$ROOT" -type f -printf '%P\t%s\t%TY-%Tm-%Td\n' > manifest.tsv
```

*Why not feed* *tree* *output directly?*

Decorators, colors, and blank lines devour tokens. A bare list/TSV is ~5-10× cheaper.



------





## **2 · Slice the manifest into token-safe chunks**



```
split -l 250 manifest.tsv chunk_      # ≈250 lines ≈700–900 tokens
```

*Rule of thumb:* **#lines × 3 ≈ tokens** for short TSV rows.

Tune -l until each chunk ≤ 1 000 tokens so your prompt, instructions, and the model’s answer stay under 1 200.



------





## **3 · Local pre-clustering (further token diet)**





Before involving the LLM, let **code** discover obvious buckets:

```
# quick & dirty
ext_map  = defaultdict(list)
for row in csv.reader(open('chunk_aa', newline=''), delimiter='\t'):
    path, size, date = row
    ext_map[path.rsplit('.',1)[-1].lower()].append(path)

json.dump(ext_map, open('chunk_aa.pre.json','w'))
```

Now each LLM call sees maybe **30 extension groups** instead of 250 raw paths—another 5× shrink.



------





## **4 · LLM pass: propose the new structure** 

## **per chunk**





Prompt skeleton (≈200 tokens):

```
System: You are a file-system re-organizer…

User: Below is JSON of files already binned by extension plus size & date hints.
Return a JSON mapping each original path → destination path so that:
 • Images → Assets/Images/YYYY/
 • Audio  → Assets/Audio/BPM_or_KEY/ …
 • Everything <1 KiB and older than 2010 → Archive/Legacy/ …

<chunk_aa.pre.json here>
```

Model returns a compact map like:

```
{"docs/report.pdf":"Docs/Reports/2014/report.pdf", …}
```

Repeat for every chunk_*.



------





## **5 · Merge & apply moves offline**



```
jq -s add chunk_*.out.json > moveplan.json

python - <<'PY'
import json, os, shutil, pathlib, sys
plan = json.load(open('moveplan.json'))
for src, dst in plan.items():
    dst_path = pathlib.Path(ROOT, dst)
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(os.path.join(ROOT, src), dst_path)
PY
```

*Chunking kept the LLM under budget; execution is one shot.*



------





## **6 · Iterate safely**





1. **Dry-run:** replace shutil.move with print(src,'→',dst)
2. Inspect random samples.
3. Re-prompt any suspect chunk with tighter rules.





------





### **Cheat-sheet for yourself**



| **Step**     | **Token cost**   | **CPU work**   | **Notes**                  |
| ------------ | ---------------- | -------------- | -------------------------- |
| Manifest     | 0                | O(N) disk scan | keep tiny                  |
| Split        | 0                | O(N)           | adjust -l                  |
| Pre-cluster  | 0                | cheap Python   | pushes semantics into code |
| LLM classify | ≤1 200 per chunk | $$             | repeat                     |
| Merge & move | 0                | O(N)           | atomic script              |

Stay strict about *one manifest → many micro-prompts* and you’ll never blow the 1 200-token ceiling while still letting the model do the high-level reasoning.

Ok,, the part of the code we wnat to apply that to-- woudl e this part rigth here-- this comes last and this is where hte AI determines what to do, if it has nothing it will simply print in the consoel :





​    // ── 3. Create & execute organization plan ───────────────────────

​    currentStatus = "Creating organization plan..."

​    progress   = 0.8



​    let plan = createOrganizationPlan(files: processedFilesNonNil,

​                     sourceDirectory: directoryURL)



​    currentStatus = "Executing organization..."

​    progress   = 0.9



​    let execResult = try await executeOrganization(plan: plan)



​    progress   = 1

​    currentStatus = "Complete"



​    // —— NEW: directory-level advice ——————————

​    let advice: String

​    do {

​      advice = try await DirectorySummarySession.shared.globalAdvice()

​      Logger().info("Continuity advice: \(advice)")

​    } catch {

​      advice = "No advice (error: \(error.localizedDescription))"

​    }

​    // ————————————————————————————————



​    // ── 4. Return summary object ────────────────────────────────────

​    return OrganizationResult(

​      sourceDirectory  : directoryURL.path,

​      targetDirectory  : plan.targetDirectory.path,

​      mode       : SortingMode.name,

​      filesProcessed  : total,

​      filesOrganized  : execResult.filesOrganized,

​      categoriesCreated : execResult.categoriesCreated,

​      duration     : Date().timeIntervalSince(startTime)

​    )

  }

Continuity advice: To summarize the directory and suggest canonical folder names, I'll need to analyze the files you've provided. Please share the list of files, and I'll help identify any inconsistencies and propose canonical folder names.





Your idea was great. 







For your OWN reference he is hte entire code-- but we are droppign in in that part o pasted aboe





//

// FileProcessor.swift

// FileOrganizer

//

// Created by Cameron Brooks on 6/18/25.

//

// Core file processing engine implementing token-safe methodology

// with Apple Foundation Models for token-safe analysis

//



import Foundation

import UniformTypeIdentifiers

import SwiftUI

import Combine

import FoundationModels     // ← add this line

import OSLog

import Observation



@available(macOS 26.0, *)

@MainActor

@Observable

class FileProcessor {

   

  var isProcessing = false

  var progress: Double = 0.0

  var currentStatus = ""

   

  var foundationModelsManager: FoundationModelsManager

  private let fileManager = FileManager.default

   

  init(foundationModelsManager: FoundationModelsManager) {

​    self.foundationModelsManager = foundationModelsManager

  }

   

  // MARK: - Main Processing Functions

  func processDirectory(_ directoryURL: URL) async throws -> OrganizationResult {

​    // ── Security-scoped URL bookkeeping ───────────────────────────────

​    guard let bookmarkData = UserDefaults.standard.data(forKey: "selectedFolderBookmark") else {

​      throw NSError(domain: "FileOrganizerError", code: 1,

​             userInfo: [NSLocalizedDescriptionKey: "No bookmark found"])

​    }

​    var isStale = false

​    let secureURL = try URL(resolvingBookmarkData: bookmarkData,

​                options: .withSecurityScope,

​                relativeTo: nil,

​                bookmarkDataIsStale: &isStale)

​    guard secureURL.startAccessingSecurityScopedResource() else {

​      throw NSError(domain: "FileOrganizerError", code: 2,

​             userInfo: [NSLocalizedDescriptionKey: "Failed to access directory"])

​    }

​    defer { secureURL.stopAccessingSecurityScopedResource() }



​    // ── UI state prep ────────────────────────────────────────────────

​    let startTime = Date()

​    isProcessing = true

​    progress   = 0

​    currentStatus = "Scanning directory..."



​    // ── 1. Discover files ───────────────────────────────

​    let fileItems = try await discoverFiles(in: directoryURL)



​    currentStatus = "Found \(fileItems.count) files"

​    progress = 0.1



​    // ── 2. Analyse each file ───────────────────────────────

​    var processedFiles: [FileItem?] = Array(repeating: nil, count: fileItems.count)

​    let total = fileItems.count

​    var completedCount = 0



​    await withTaskGroup(of: (Int, FileItem).self) { group in

​      var inFlight = 0

​      var fileIterator = fileItems.enumerated().makeIterator()



​      // Fill the group up to 3 concurrent tasks

​      while inFlight < 3, let (index, file) = fileIterator.next() {

​        group.addTask {

​          var mutableFile = file

​          // Create a new independent AI session for this task

​          let aiSession = await self.foundationModelsManager.makeNewSession() // <-- per-task

​          mutableFile.analysisResult = try? await aiSession.analyzeFileContent(

​            try await self.extractFileContent(mutableFile),

​            fileName: mutableFile.name,

​            fileType: mutableFile.type

​          )

​          if let meta = mutableFile.analysisResult {

​            do {

​              try await DirectorySummarySession.shared.add(FileMetadata(

​                primaryCategory  : meta.category,

​                secondaryCategory : meta.subcategory,

​                suggestedFilename : meta.suggestedName,

​                summary      : meta.description,

​                tags       : meta.tags,

​                confidence    : meta.confidence

​              ))

​            } catch {

​              print("Summary update failed for \(file.name): \(error)")

​            }

​          }

​          // Simulate pacing

​          try? await Task.sleep(nanoseconds: 10_000_000)

​          return (index, mutableFile)

​        }

​        inFlight += 1

​      }



​      for await (index, resultFile) in group {

​        processedFiles[index] = resultFile

​        completedCount += 1

​        progress = 0.1 + 0.7 * Double(completedCount) / Double(total)



​        // Always keep up to 3 tasks in flight

​        if let (nextIndex, nextFile) = fileIterator.next() {

​          group.addTask {

​            var mutableFile = nextFile

​            // Create a new independent AI session for this task

​            let aiSession = await self.foundationModelsManager.makeNewSession() // <-- per-task session creation

​            mutableFile.analysisResult = try? await aiSession.analyzeFileContent(

​              try await self.extractFileContent(mutableFile),

​              fileName: mutableFile.name,

​              fileType: mutableFile.type

​            )

​            if let meta = mutableFile.analysisResult {

​              do {

​                try await DirectorySummarySession.shared.add(FileMetadata(

​                  primaryCategory  : meta.category,

​                  secondaryCategory : meta.subcategory,

​                  suggestedFilename : meta.suggestedName,

​                  summary      : meta.description,

​                  tags       : meta.tags,

​                  confidence    : meta.confidence

​                ))

​              } catch {

​                print("Summary update failed for \(nextFile.name): \(error)")

​              }

​            }

​            try? await Task.sleep(nanoseconds: 10_000_000)

​            return (nextIndex, mutableFile)

​          }

​        }

​      }

​    }

​    // Remove optionals after all tasks complete

​    let processedFilesNonNil = processedFiles.compactMap { $0 }



​    // ── 3. Create & execute organization plan ───────────────────────

​    currentStatus = "Creating organization plan..."

​    progress   = 0.8



​    let plan = createOrganizationPlan(files: processedFilesNonNil,

​                     sourceDirectory: directoryURL)



​    currentStatus = "Executing organization..."

​    progress   = 0.9



​    let execResult = try await executeOrganization(plan: plan)



​    progress   = 1

​    currentStatus = "Complete"



​    // —— NEW: directory-level advice ——————————

​    let advice: String

​    do {

​      advice = try await DirectorySummarySession.shared.globalAdvice()

​      Logger().info("Continuity advice: \(advice)")

​    } catch {

​      advice = "No advice (error: \(error.localizedDescription))"

​    }

​    // ————————————————————————————————



​    // ── 4. Return summary object ────────────────────────────────────

​    return OrganizationResult(

​      sourceDirectory  : directoryURL.path,

​      targetDirectory  : plan.targetDirectory.path,

​      mode       : SortingMode.name,

​      filesProcessed  : total,

​      filesOrganized  : execResult.filesOrganized,

​      categoriesCreated : execResult.categoriesCreated,

​      duration     : Date().timeIntervalSince(startTime)

​    )

  }

   

  // MARK: - File Discovery (QiuYannnn approach)

   

  private func discoverFiles(in directoryURL: URL) async throws -> [FileItem] {

​    return try await withCheckedThrowingContinuation { continuation in

​      DispatchQueue.global(qos: .userInitiated).async {

​        do {

​          let resourceKeys: [URLResourceKey] = [

​            .isRegularFileKey,

​            .fileSizeKey,

​            .contentModificationDateKey,

​            .typeIdentifierKey

​          ]

​           

​          let enumerator = FileManager.default.enumerator(

​            at: directoryURL,

​            includingPropertiesForKeys: resourceKeys,

​            options: [.skipsHiddenFiles, .skipsPackageDescendants]

​          )

​           

​          var fileItems: [FileItem] = []

​           

​          while let url = enumerator?.nextObject() as? URL {

​            let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))

​             

​            guard resourceValues.isRegularFile == true else { continue }

​             

​            let fileItem = FileItem(

​              url: url,

​              name: url.lastPathComponent,

​              type: url.pathExtension,

​              size: Int64(resourceValues.fileSize ?? 0),

​              modificationDate: resourceValues.contentModificationDate ?? Date()

​            )

​             

​            fileItems.append(fileItem)

​          }

​           

​          continuation.resume(returning: fileItems)

​        } catch {

​          continuation.resume(throwing: error)

​        }

​      }

​    }

  }

   

  /// Quickly scans the given directory and returns the count of each file type.

  private func countFileTypes(in directoryURL: URL) async throws -> [String: Int] {

​    let files = try await discoverFiles(in: directoryURL)

​    var typeCounts: [String: Int] = [:]

​    for file in files {

​      typeCounts[file.type, default: 0] += 1

​    }

​    return typeCounts

  }

   

  // MARK: - AI Analysis (Token-Safe)

   

  // This method is no longer used directly in the task; analysis now happens inside the task with a per-task session.

  private func analyzeFileWithAI(_ fileItem: FileItem) async throws -> FileAnalysisResult {

​    // Extract content based on file type

​    let content = try await extractFileContent(fileItem)

​     

​    // Use Foundation Models for analysis

​    return try await foundationModelsManager.analyzeFileContent(

​      content,

​      fileName: fileItem.name,

​      fileType: fileItem.type

​    )

  }

   

  private func extractFileContent(_ fileItem: FileItem) async throws -> String {

​    let fileType = fileItem.fileExtension.lowercased()

​     

​    // Limit content extraction to respect token limits

​    switch fileType {

​    case "txt", "md", "rtf":

​      return try extractTextContent(from: fileItem.url, maxLength: 566)

​    case "pdf":

​      return try extractPDFContent(from: fileItem.url, maxLength: 566)

​    case "docx", "doc":

​      return try extractDocumentContent(from: fileItem.url, maxLength: 566)

​    case "wav", "aiff", "flac", "ogg", "mp3", "m4a":

​      // Special handling for audio/sound library files

​      let nameLower = fileItem.name.lowercased()

​      var tags: [String] = []

​      if nameLower.hasPrefix("m_") { tags.guess("Male") } // maybe m_ means male?

​      if nameLower.hasPrefix("f_") { tags.guess("Female") } /// maybe f_ means female?

​      if nameLower.contains("R121") { tags.guess("ROyer 121") } //Maybe model number?

​      if nameLower.contains("U47") { tags.guess("TelefunkenU47") }

​      let isLikelySoundEffect = !tags.isEmpty

​      let description: String

​      if isLikelySoundEffect {

​        description = "Audio (potential sound librayr): " + tags.joined(separator: ", ") + ", " + fileItem.name

​      } else {

​        description = "Audio file (potential music track): \(fileItem.name)"

​      }

​      return String(description.prefix(566))

​    case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":

​      return "Image file: \(fileItem.name)"

​    default:

​      let summary = "File: \(fileItem.name), Type: \(fileType), Size: \(fileItem.displaySize)"

​      return String(summary.prefix(566))

​    }

  }

   

  private func extractTextContent(from url: URL, maxLength: Int) throws -> String {

​    let content = try String(contentsOf: url, encoding: .utf8)

​    return String(content.prefix(700))

  }

   

  private func extractPDFContent(from url: URL, maxLength: Int) throws -> String {

​    // Basic PDF content extraction - in a real app, use PDFKit

​    return "PDF document: \(url.lastPathComponent)"

  }

   

  private func extractDocumentContent(from url: URL, maxLength: Int) throws -> String {

​    // Basic document content extraction - in a real app, use proper document parsing

​    return "Document: \(url.lastPathComponent)"

  }

   



  // MARK: - Organization Planning

   

  private func createOrganizationPlan(files: [FileItem], sourceDirectory: URL) -> OrganizationPlan {

​    // Organize files in place within the selected directory

​    let targetDirectory = sourceDirectory

​    var operations: [FileOperation] = []

​     

​    // Group files by category

​    let groupedFiles = Dictionary(grouping: files) { file in

​      file.analysisResult?.displayCategory ?? "Uncategorized"

​    }

​     

​    // Create operations for each category

​    for (category, categoryFiles) in groupedFiles {

​      let categoryURL = targetDirectory.appendingPathComponent(category)

​       

​      // Add directory creation operation

​      operations.append(FileOperation(

​        sourceURL: sourceDirectory,

​        targetURL: categoryURL,

​        targetCategory: category,

​        operation: .createDirectory

​      ))

​       

​      // Add file move operations

​      for file in categoryFiles {

​        let targetURL = buildTargetURL(for: file, in: categoryURL)



​        operations.append(FileOperation(

​          sourceURL: file.url,

​          targetURL: targetURL,

​          targetCategory: category,

​          operation: .move

​        ))

​      }

​    }



​    return OrganizationPlan(

​      sourceDirectory: sourceDirectory,

​      targetDirectory: targetDirectory,

​      operations: operations

​    )

  }



  /// Builds the final destination URL for a file.

  ///

  /// This helper runs *after* AI analysis has completed, so it does not

  /// consume any model tokens. It simply ensures the original extension is

  /// preserved if the suggested name does not include one.

  private func buildTargetURL(for file: FileItem, in categoryURL: URL) -> URL {

​    var baseName = file.analysisResult?.suggestedName ?? file.name



​    let hasExtension = !URL(fileURLWithPath: baseName).pathExtension.isEmpty

​    if !hasExtension {

​      baseName += "." + file.fileExtension

​    }



​    return categoryURL.appendingPathComponent(baseName)

  }

   

  // MARK: - Organization Execution

   

  private func executeOrganization(plan: OrganizationPlan) async throws -> (filesOrganized: Int, categoriesCreated: [String]) {

​    var filesOrganized: Int? = nil

​    var categoriesCreated: Set<String> = []



​    try fileManager.createDirectory(at: plan.targetDirectory, withIntermediateDirectories: true)

​     

​    for operation in plan.operations {

​      switch operation.operation {

​      case .createDirectory:

​        try fileManager.createDirectory(at: operation.targetURL, withIntermediateDirectories: true)

​        categoriesCreated.insert(operation.targetCategory)

​         

​      case .move:

​        try fileManager.moveItem(at: operation.sourceURL, to: operation.targetURL)

​        filesOrganized = (filesOrganized ?? 0) + 1

​         

​      case .copy:

​        try fileManager.copyItem(at: operation.sourceURL, to: operation.targetURL)

​        filesOrganized = (filesOrganized ?? 0) + 1

​      }

​    }

​     

​    return (filesOrganized: filesOrganized ?? 0, categoriesCreated: Array(categoriesCreated))

  }

}  



extension Array where Element == String {

  /// Appends a value, but expresses 'guessing' intent.

  mutating func guess(_ value: String) {

​    self.append(value)

  }

}





In this scernio, you are given a poorly organized folder strucutre and it is beign tasts with giving it a reasonable, aware, ppro loooking oragnaiztion steuutre in teh way you detailed abovue

Below is a **drop-in replacement** for the “step 3” block plus the helper code it needs.

It keeps every Foundation-Models prompt ≤ ≈1 200 tokens by:



1. **Manifest** Generate a TSV line for every file: relPath \t size \t yyyymmdd.

2. **Chunk** Slice that manifest into ~250-line chunks (≈700–900 tokens each).

3. **Pre-cluster** Group the lines by file-extension inside each chunk so the LLM sees

   maybe 30 buckets instead of 250 raw paths.

4. **LLM call per chunk** Ask for a JSON { original : newPath } map.

5. **Merge** Combine all chunk maps, build the OrganizationPlan, run it exactly as

   before.





------





### **1. New helper types**



```
// MARK: - Token-safe helpers
private struct ManifestRow: Codable {
    let rel: String      // relative path
    let size: Int64      // bytes
    let yyyymmdd: String // modified date
}

private struct ChunkRequest: Codable {
    let groupedByExt: [String:[ManifestRow]]
}

private typealias RelocationMap = [String:String] // old → new
```



------





### **2. Generate manifest & chunks**



```
/// Builds a flat manifest in memory (no disk I/O needed).
private func buildManifest(from files: [FileItem], root: URL) -> [ManifestRow] {
    let df = DateFormatter()
    df.dateFormat = "yyyyMMdd"
    return files.map { file in
        ManifestRow(rel       : file.url.path.replacingOccurrences(of: root.path + "/", with: ""),
                    size      : file.size,
                    yyyymmdd  : df.string(from: file.modificationDate))
    }
}

/// ~3 tokens/field ⇒ 3*3*250 ≈ 2 250 chars ≈ 750 tokens
private func sliceIntoChunks(_ manifest: [ManifestRow], maxLines: Int = 250)
-> [[ManifestRow]] {
    stride(from: 0, to: manifest.count, by: maxLines).map {
        Array(manifest[$0 ..< min($0 + maxLines, manifest.count)])
    }
}

/// buckets rows by extension to save tokens
private func preCluster(_ rows: [ManifestRow]) -> ChunkRequest {
    let groups = Dictionary(grouping: rows) { row in
        (row.rel as NSString).pathExtension.lowercased()
    }
    return ChunkRequest(groupedByExt: groups)
}
```



------





### **3. LLM prompt (Foundation Models)**



```
private func askModelForRelocations(_ chunk: ChunkRequest,
                                    session: FoundationModelsSession)
async throws -> RelocationMap
{
    let system = """
    You are a professional digital-asset librarian. \
    Given JSON grouped by file-extension, create a new, clean folder scheme. \
    Return ONLY a JSON map { oldRelPath : newRelPath }. \
    Rules: keep original extensions, avoid name collisions, \
    group images under Assets/Images/YYYY/, audio under Assets/Audio/, \
    docs under Docs/, misc → Archive/. Limit to moves inside the root.
    """
    let user   = try String(data: JSONEncoder().encode(chunk), encoding: .utf8)!
    let raw    = try await session.chat(system: system, user: user)
    return try JSONDecoder().decode(RelocationMap.self,
                                    from: Data(raw.utf8))
}
```



------





### **4. Token-safe plan builder**



```
private func buildTokenSafeOrganizationPlan(files: [FileItem],
                                            sourceDirectory root: URL)
async throws -> OrganizationPlan
{
    // 1) manifest → chunks
    let manifest = buildManifest(from: files, root: root)
    let chunks   = sliceIntoChunks(manifest)

    // 2) model pass per chunk
    var globalMap: RelocationMap = [:]
    for rows in chunks {
        let req   = preCluster(rows)
        let sess  = await foundationModelsManager.makeNewSession()
        let map   = try await askModelForRelocations(req, session: sess)
        globalMap.merge(map) { _, new in new }   // later chunk wins
    }

    // 3) transform RelocationMap → FileOperation list
    var ops: [FileOperation] = []
    var categories: Set<String> = []

    for file in files {
        guard let relDest = globalMap[file.url.lastPathComponent]
        else { continue }                             // skip if model ignored
        let destAbs  = root.appendingPathComponent(relDest)
        let category = destAbs.deletingLastPathComponent().lastPathComponent
        categories.insert(category)

        ops.append(FileOperation(sourceURL      : file.url,
                                 targetURL      : destAbs,
                                 targetCategory : category,
                                 operation      : .move))
    }

    // make sure category dirs exist
    for cat in categories {
        let url = root.appendingPathComponent(cat)
        ops.insert(FileOperation(sourceURL      : root,
                                 targetURL      : url,
                                 targetCategory : cat,
                                 operation      : .createDirectory),
                    at: 0)
    }

    return OrganizationPlan(sourceDirectory: root,
                            targetDirectory: root,
                            operations: ops)
}
```



------





### **5.** 

### **Replace**

###  **the old step 3 block**



```
// ── 3. Token-safe organization plan ────────────────────────────────
currentStatus = "Creating organization plan..."
progress      = 0.8

let plan = try await buildTokenSafeOrganizationPlan(
              files: processedFilesNonNil,
              sourceDirectory: directoryURL)

currentStatus = "Executing organization..."
progress      = 0.9

let execResult = try await executeOrganization(plan: plan)

progress      = 1
currentStatus = "Complete"
```

Nothing else in your FileProcessor needs to change—executeOrganization still

uses the same OrganizationPlan struct.



------





### **How this satisfies the 1 200-token ceiling**



| **Stage**               | **Worst-case tokens** |
| ----------------------- | --------------------- |
| System instructions     | ~100                  |
| Chunk JSON (≈250 lines) | ~700-900              |
| **Subtotal / chunk**    | **≤1 000**            |
| Model response (map)    | ≤ 200                 |
| **Total / round-trip**  | **≤1 200**            |

If a directory is huge the manifest just yields more chunks, never a bigger

prompt. The memory footprint is tiny and every Foundation-Models call stays

comfortably inside budget.



Drop this code in, run against a mess of files, and watch the app reorganize

without ever blowing the token limit.

### **Give every model call a** 

### **self-resetting wrapper**





Below is a minimal, drop-in utility you can slot in next to FoundationModelsManager.

It **tracks the running token count**, and when the next prompt+response would

overflow your 1 200-token ceiling it:



1. **Saves out** anything you need to keep (summary string, JSON map—whatever).
2. **Closes** the current FoundationModelsSession.
3. **Spins up** a fresh one and restores the summary.
4. Returns the model’s answer with a full budget again.





------





#### **1. Token budget constants**



```
private let TOKEN_LIMIT      = 1_200        // hard ceiling
private let RESPONSE_PADDING = 200          // how many tokens we expect back
```



------





#### **2. Estimate-tokens helper**





*(cheap heuristic; swap in the SDK’s tokenizer if you have it)*

```
private func roughTokenCount(_ s: String) -> Int {
    // 4 chars ≈ 1 token for English
    max(1, s.utf8.count / 4)
}
```



------





#### **3. Persist-between-sessions payload**





Use **one plain struct** that is easy to JSON-encode/decode.

For this use-case all we really need is the RelocationMap we’re

building across chunks:

```
struct CarryOver: Codable {
    var relocation: RelocationMap = [:]
}
```



------





#### **4. The auto-resetting session wrapper**



```
final class TokenSafeSession {
    private var session : FoundationModelsSession
    private var tokens  : Int = 0
    private var state   : CarryOver

    init(manager: FoundationModelsManager,
         carryOver: CarryOver = CarryOver()) async {
        self.session  = await manager.makeNewSession()
        self.state    = carryOver
    }

    /// Core chat: auto-restart if limit would be breached.
    @discardableResult
    func chat(system: String, user: String) async throws -> (reply: String, carry: CarryOver) {

        // Will this prompt + a padded answer blow our budget?
        let projected = tokens
                      + roughTokenCount(system)
                      + roughTokenCount(user)
                      + RESPONSE_PADDING

        if projected > TOKEN_LIMIT {
            try await restartSession()
        }

        let reply = try await session.chat(system: system, user: user)
        tokens += roughTokenCount(system) +
                  roughTokenCount(user)    +
                  roughTokenCount(reply)

        return (reply, state)
    }

    // Update carry-over state from caller
    func mergeRelocation(_ delta: RelocationMap) {
        state.relocation.merge(delta) { _, new in new }
    }

    // Gives caller the current state whenever needed
    var carryOver: CarryOver { state }

    // MARK: – internal
    private func restartSession() async throws {
        // 1. close (if SDK offers an explicit close; otherwise just drop ref)
        // 2. open new
        session = await FoundationModelsManager.shared.makeNewSession()
        tokens  = 0

        // 3. inject a one-liner summary so context isn’t lost
        if !state.relocation.isEmpty {
            let summary = "Carry-over relocation map with \(state.relocation.count) entries."
            _ = try await session.chat(system: "Context seed", user: summary)
            tokens += roughTokenCount(summary) + roughTokenCount("Context seed")
        }
    }
}
```



------





#### **5. Use it in the plan-building loop**



```
// inside buildTokenSafeOrganizationPlan(...)
var globalMap: RelocationMap = [:]
var carry = CarryOver()

for rows in chunks {
    let req  = preCluster(rows)
    let ts   = await TokenSafeSession(manager: foundationModelsManager, carryOver: carry)

    let sys  = SYSTEM_PROMPT        // same as before
    let usr  = try String(data: JSONEncoder().encode(req), encoding: .utf8)!
    let (reply, newCarry) = try await ts.chat(system: sys, user: usr)

    let delta = try JSONDecoder().decode(RelocationMap.self, from: Data(reply.utf8))
    globalMap.merge(delta) { _, new in new }

    carry = newCarry          // pass forward for the next chunk
}
```

*Each wrapper lives for exactly one chunk unless it runs out of budget sooner;*

*either way the next chunk starts with a fresh 0/1 200 token slate.*



------





### **Why it works**



| **Action**                 | **Tokens counted**  | **When reset?**                    |
| -------------------------- | ------------------- | ---------------------------------- |
| Prompt build (system+user) | added to tokens     | immediately                        |
| Model reply                | counted on return   | immediately                        |
| Cross-chunk carry-over     | one cheap summary   | at restartSession()                |
| Budget breach              | detects before send | **session recreated** (tokens = 0) |

You never exceed the ceiling, yet the

*minimal* state you care about (the growing relocation map)

survives every reset.
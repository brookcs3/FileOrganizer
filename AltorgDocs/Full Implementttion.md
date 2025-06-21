# **AI-Driven Folder Organization System Redesign**







## **Overview**





This redesign outlines a **Swift-based folder organization system** that uses AI (Apple’s Foundation Models) to intelligently reorganize files, fully integrated with a robust restore mechanism. The new design focuses on correctness, clarity, and extensibility, unifying several key features:



- **Token-Safe Chunking:** The system builds a manifest of all files and splits it into chunks that fit within a safe token budget (≤ ~1,200 tokens per prompt). This prevents overrunning the model’s context window.
- **Adaptive LLM Sessions:** It runs AI (LLM) analysis on each chunk with prompts that include file content/metadata. The session manager tracks token usage and *auto-resets* the model’s context when budgets are exceeded, while preserving important context (carry-over of categorization decisions).
- **Organization Plan Assembly:** AI suggestions from each chunk are aggregated into a cohesive OrganizationPlan – a structured list of planned file moves (e.g. file UUID → new folder path).
- **RestoreManager Integration:** Every file is tagged with a persistent UUID and every move is tracked. The RestoreManager tags files using extended file attributes and can generate a **restore snapshot** (Markdown file) mapping each file’s UUID to its original path. This allows one-click reversal of the reorganization.
- **Dry-Run Mode:** Supports a “**emitRestoreOnly**” mode that performs a simulated run. In dry-run, the system produces a **fake restore snapshot** (without moving any files) so the user can review the plan or test the restore process. No user files are actually touched in this mode.





The result is a single, cohesive pipeline that efficiently plans a reorganization using AI, logs every operation for auditability, and can instantly undo any changes if needed.





## **System Architecture and Workflow**





The system is organized into modular components that handle distinct concerns. The high-level workflow is as follows:



1. **Manifest Building & UUID Tagging:** Recursively scan the target directory and build a manifest of all files (with relevant metadata). Use RestoreManager to ensure each file has a unique UUID tag and gather original file info into a list of FileSnapshot records  .

2. **Chunking Large Manifests:** Split the manifest data into **LLM-safe chunks** (e.g. each chunk corresponding to a set of files whose description fits within ~1,200 tokens when prompted). Ensure each chunk is formatted (TSV or similar) for easy parsing by the model.

3. **AI Planning per Chunk:** For each chunk, feed the file list to the AI model with a prompt asking for optimal folder categorizations. Manage the model session to not exceed token limits:

   

   - Continue in the same session for as long as possible to maintain conversational context.
   - If adding a new chunk would exceed the token budget, gracefully reset the session **after preserving key context** (e.g. previously decided categories) in the next prompt.

   

4. **OrganizationPlan Assembly:** Parse the model’s output for each chunk to build a combined OrganizationPlan – mapping each file’s UUID to its new target directory (or full path). This plan represents the complete reorganization proposed by the AI.

5. **Integrate Restore Tracking:** As the plan is built (or after it’s finalized), record the planned moves. Because every file is identified by UUID, we can use RestoreManager to log original locations and later find files in their new locations by UUID. If *emitRestoreOnly* (dry-run) is enabled, stop here and output a restore snapshot.

6. **Execute Moves (or Dry Run):** If not a dry-run, proceed to physically **execute the moves** on the file system (creating new folders as needed, moving each file). Each move operation is tracked via RestoreManager to enable reversal. Finally, output or save a .restore.md snapshot (in dry-run this snapshot is “fake” because no moves occurred, but it shows what would be needed to restore)  .





Below we detail each component/module in this architecture, including class structures and their interactions.





## **Data Structures and Core Classes**





To keep the system organized, we define a few core data structures and classes:

```
/// Represents a file and its metadata in the manifest.
struct FileManifestEntry {
    let url: URL               // Full path to the file
    let uuid: UUID             // Unique identifier (for tracking)
    let fileName: String       // Name of the file
    let originalPath: String   // Original path relative to root (for restore)
    let size: Int64            // File size in bytes
    let creationDate: Date
    let modificationDate: Date
    // Additional metadata or content summary can be included as needed.
}

/// Holds the planned new location for each file (UUID → new relative path).
struct OrganizationPlan {
    // Map each file’s UUID to a new relative path (directory + file name).
    var plannedMoves: [UUID: String] = [:]
    
    mutating func addMove(fileID: UUID, newRelativePath: String) {
        plannedMoves[fileID] = newRelativePath
    }
}

/// Orchestrator that coordinates the entire reorganization process.
class FolderOrganizer {
    private let manifestBuilder: ManifestBuilder
    private let chunker: ManifestChunker
    private let aiPlanner: AIReorganizationPlanner
    private let restoreManager = RestoreManager.self  // Use RestoreManager's static methods
    
    init(model: FoundationModel) {
        self.manifestBuilder = ManifestBuilder()
        self.chunker = ManifestChunker(maxTokens: 1200)
        self.aiPlanner = AIReorganizationPlanner(model: model, tokenBudget: 1200)
    }
    
    func organizeDirectory(rootURL: URL, emitRestoreOnly: Bool) throws {
        // Implementation detailed below...
    }
}
```



- **FileManifestEntry:** a struct describing each file (including its path, UUID, and metadata). This is essentially the manifest record that will be fed to the AI. It contains everything needed for both AI decisions and restore operations. (We could also reuse RestoreManager.FileSnapshot for similar information , but a separate type makes the design more extensible – e.g., we can add fields like content summary or classification tags without altering RestoreManager internals.)
- **OrganizationPlan:** a simple structure collecting the AI’s decisions. It maps each file’s UUID to its new intended location (as a relative path from the root). This could be extended to include more details (like whether a new folder needs creation, or a different filename if renaming were supported), but for now it encapsulates “file X goes to location Y”. It provides a method to add moves; we could also add methods to output a summary or apply the plan.
- **FolderOrganizer:** the high-level orchestrator class. It composes the other components – a ManifestBuilder for scanning files, a ManifestChunker for splitting input, an AIReorganizationPlanner for AI interactions, and uses the RestoreManager for tagging and snapshots. Its main method organizeDirectory(rootURL:emitRestoreOnly:) runs the full pipeline. We pass in a FoundationModel instance to the planner via the initializer, allowing flexibility to plug in any large language model (on-device or cloud).





Now, let’s look at each stage in detail, with focus on class responsibilities and interactions.





## **Manifest Construction & UUID Tagging**





**ManifestBuilder:** This component is responsible for traversing the directory tree and gathering file info into a manifest list. In our design, ManifestBuilder.buildManifest(rootURL) will:



- Use FileManager or similar to recursively enumerate all files under rootURL.

- **Integrate RestoreManager:** For each file, fetch or assign a UUID using RestoreManager. Specifically, call RestoreManager.tagAllFilesInTree(rootURL:) to tag everything in one pass and collect metadata snapshots  . This returns an array of FileSnapshot records (each contains the file’s UUID, original relative path, name, size, dates, etc.).

  

  - Under the hood, tagAllFilesInTree uses extended file attributes to store a unique identifier on each file if not already present . It also skips special files like any existing .restore.md . This ensures *every file is uniquely tagged and trackable* before we move anything.

  

- Transform each FileSnapshot into our FileManifestEntry (or we can directly use FileSnapshot data). The originalPath from the snapshot is stored for restore purposes , and the UUID is stored for linking to AI output and for logging.





By leveraging RestoreManager at this stage, we ensure **every file in the manifest has a persistent ID**. This is crucial: no matter how the file is moved or renamed later, the UUID stays with it (in metadata), so we can always find it by UUID for restoration.



**Example Implementation:**

```
class ManifestBuilder {
    func buildManifest(root: URL) -> [FileManifestEntry] {
        // Tag all files and get snapshots of original state
        let snapshots = RestoreManager.tagAllFilesInTree(rootURL: root)
        // Convert snapshots to manifest entries
        return snapshots.map { snap in 
            FileManifestEntry(url: root.appendingPathComponent(snap.originalPath),
                              uuid: UUID(uuidString: snap.uuid)!,
                              fileName: snap.fileName,
                              originalPath: snap.originalPath,
                              size: snap.fileSize,
                              creationDate: snap.creationDate,
                              modificationDate: snap.modificationDate)
        }
    }
}
```

After this step, we have a complete list of files ([FileManifestEntry]). Each entry is enriched with the file’s metadata and a UUID. We also keep the full list of FileSnapshots or FileManifestEntrys, which will later be used to create the restore snapshot.





## **Token-Safe Manifest Chunking**





For large directories, the manifest could be too big to send to the LLM in one shot (the model’s context is limited). We implement a ManifestChunker that splits the file list into chunks that respect the token budget.



**ManifestChunker:** This class takes the full manifest and breaks it into chunks of a specified maximum token size. Key responsibilities:



- Estimate the token count of each file’s description entry. For example, if we plan to feed the model lines like “UUID <tab> originalPath <tab> fileName <tab> size <tab> date…”, we can estimate tokens by counting words or characters. We might use a simple heuristic (e.g. 1 token ≈ 4 characters) or use a tokenizer if available for our model to precisely count.
- Group entries into chunks such that the total tokens per chunk (plus some overhead for prompt text) does not exceed the limit (1200 tokens). We leave headroom for the model’s response as well (for instance, target maybe 1000 tokens of input, reserving ~200 for output).
- Ensure that chunk boundaries do not break logical groupings if any (in this case, each file entry is independent, so just fill chunks sequentially).





The output is an array of chunks, e.g. [[FileManifestEntry]]. Each chunk can be formatted into a prompt separately.



For example, if we have 500 files, the chunker might split them into 5 chunks of 100 files each (depending on file name lengths and metadata). Each chunk corresponds to a self-contained list of files the model will consider.



**Chunk Format (TSV-style):** To make parsing easy for the LLM, we format each file entry as a line with consistent structure, for example:

```
<UUID>\t<Filename>\t<Size> bytes\t<CreationDate>\t<Metadata...>
```

We include the UUID in the prompt so the model can reference it in its answer. This avoids confusion if there are duplicate names, and simplifies mapping results back to files. The model will be instructed to use the UUID when suggesting a target folder for each file.



**Code Snippet (Chunking logic):**

```
class ManifestChunker {
    private let maxTokens: Int
    
    init(maxTokens: Int) { self.maxTokens = maxTokens }
    
    func chunkManifest(_ entries: [FileManifestEntry]) -> [[FileManifestEntry]] {
        var chunks: [[FileManifestEntry]] = []
        var currentChunk: [FileManifestEntry] = []
        var currentTokenCount = 0
        
        for entry in entries {
            // Estimate tokens for this entry (e.g., based on string length)
            let entryDescription = "\(entry.uuid.uuidString)\t\(entry.fileName)\t\(entry.size) bytes\t\(entry.creationDate)"
            let entryTokens = estimateTokens(entryDescription)
            // If adding this entry would exceed budget, start a new chunk
            if currentTokenCount + entryTokens > maxTokens {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = []
                currentTokenCount = 0
            }
            currentChunk.append(entry)
            currentTokenCount += entryTokens
        }
        // Append the final chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        return chunks
    }
    
    private func estimateTokens(_ text: String) -> Int {
        // Rough estimate: 1 token ~4 chars (adjust or use tokenizer as needed)
        return max(1, text.count / 4)
    }
}
```

The above demonstrates a simple heuristic approach. In practice, if the Foundation Model API provides a tokenizer or if we integrate a library for token counting, we would use that for accuracy. The goal is to ensure each chunk’s text + prompt stays within limits.





## **AI Session Management & Per-Chunk Processing**





Once the manifest is chunked, we use an AI planner to analyze each chunk and propose how to reorganize those files. The **AIReorganizationPlanner** (or simply AIPlanner) class encapsulates interactions with the Foundation Model, including prompt construction, token budget management, and session resets.



**AIReorganizationPlanner:** Key responsibilities and design:



- **Model Interaction:** It holds a reference to the loaded FoundationModel (LLM) instance. This could be an on-device model provided by Apple’s Framework or an external API wrapper – the planner abstracts that away.
- **Prompt Template:** It defines how to prompt the model. For example, the prompt may look like:



```
SYSTEM: You are an AI that organizes files into folders based on content and metadata.
USER: Given the following files (with UUID, name, size, date, etc.), propose an ideal folder/category for each. 
Files:
UUID1   name1.ext   1234 bytes   2021-01-01 ...
UUID2   name2.ext   5678 bytes   2020-12-05 ...
...
Please output a mapping of each UUID to a suggested folder path (e.g. "UUID1 -> Project/Reports").
```



- Each chunk will be inserted into such a template. The model’s task is to output lines mapping each file ID to a folder (or new path). We instruct the model to keep responses terse and structured for easy parsing.

- **Token Budget Tracking:** The planner keeps track of how many tokens have been used in the current session. If using a chat-style interface, every prompt and response accumulates in the context. The planner must decide whether to continue the conversation or start fresh for the next chunk.

- **Session Auto-Reset with Carry-Over:** To maintain continuity across chunks without overrunning context limits, the planner does the following:

  

  - Process the first chunk with a fresh session (including any initial system prompt explaining the task).
  - After getting a response, extract any *global organizational structure* the model has started to form. Typically, this might be the set of category folders it decided to use. For example, if the model output shows folders “Work/Docs”, “Personal/Photos”, “Archive” for chunk 1, those are now established categories.
  - When moving to chunk 2, check if adding the new chunk’s prompt (plus prior conversation) exceeds ~1200 tokens. If not, we can continue the conversation, sending chunk 2 files as the next user prompt. The model already “knows” what it suggested for chunk 1 from context.
  - **If it would exceed the budget**, we reset the session: start a new conversation with the model. To preserve context, we include a brief summary of what was decided so far as part of the new session’s initial prompt. For example: *“So far, files have been organized into folders: Work/Docs, Personal/Photos, Archive. Now organize the next batch of files.”* This carry-over ensures the model doesn’t contradict or repeat earlier decisions. Then we present chunk 2 files.
  - Continue this process for all chunks, possibly spanning multiple sessions if needed, each time seeding the new session with the cumulative plan/state so far.

  

- **Parsing Model Output:** The planner will parse the model’s text output into structured data (e.g. a list of (UUID, newFolderPath) pairs). It has to handle the model’s format as prompted. If we asked for UUID -> Folder, we can split on an arrow or use regex to extract the pieces. Any files not mentioned or unclear suggestions can be handled (e.g. if the model misses a file, we could default it to an “Unsorted” folder or ask again – those details can be part of the prompt instructions to avoid missing mappings).





**Session management example:** Suppose the token limit is 1200 and chunk1 used 800 tokens (prompt + response). Chunk2 is another 700 tokens needed. Continuing would total 1500 (>1200), so we decide to reset. The planner would start a new session for chunk2 with a system prompt like: *“Continue the organization. The following folders have been established so far: [list]. Organize the next files accordingly.”* then list chunk2 files. The model, even in a new session, now knows the context (which we explicitly provided) and will output folder assignments consistent with the earlier ones. This design balances **context continuity** with **token limit safety**.



**AIReorganizationPlanner Code Outline:**

```
class AIReorganizationPlanner {
    private let model: FoundationModel  // LLM instance providing a generate API
    private let tokenBudget: Int
    private var conversationContext: LLMConversationContext  // pseudotype for managing chat context
    private var usedTokens: Int = 0
    
    init(model: FoundationModel, tokenBudget: Int) {
        self.model = model
        self.tokenBudget = tokenBudget
        self.conversationContext = LLMConversationContext(model: model)
        // (LLMConversationContext is a helper to manage messages and context; for example, it might store system and user messages.)
    }
    
    /// Processes a chunk of files and returns an array of (UUID, targetPath) suggestions.
    func planChunk(_ files: [FileManifestEntry], carryOverSummary: String?) throws -> [(UUID, String)] {
        // If a summary of previous decisions is provided and context is fresh, include it
        if let summary = carryOverSummary {
            conversationContext.reset() 
            conversationContext.setSystemPrompt("You are an AI file organizer...")  // base instruction
            conversationContext.addUserMessage("Previously organized folders: \(summary)")
        }
        // Formulate user prompt with the current chunk's file list
        let fileListText = files.map { formatEntry($0) }.joined(separator: "\n")
        let prompt = "Organize the following files:\n\(fileListText)\n\nOutput as `UUID -> FolderName` for each."
        conversationContext.addUserMessage(prompt)
        
        // Check token usage; if exceeding budget, throw or handle by requiring reset (the logic for deciding reset happens outside, before calling this function)
        // (In practice, we would calculate the token count for conversationContext and compare to tokenBudget here.)
        
        // Generate model response
        let response = try model.generate(from: conversationContext)  // pseudocode for generation
        
        usedTokens += conversationContext.lastExchangeTokenCount  // update usage
        // Parse the response into [(UUID, String)]
        return parseResponse(response)
    }
    
    /// Resets the model session but returns a summary string of the plan so far to carry into the next session.
    func resetSessionAndSummarize(plan: OrganizationPlan) -> String {
        // Extract a concise summary of current plan (e.g., list of category folders used so far)
        let categories = Set(plan.plannedMoves.values.map { 
            // top-level folder of each path
            ($0 as NSString).pathComponents.first ?? $0 
        })
        return categories.sorted().joined(separator: ", ")
    }
    
    private func formatEntry(_ file: FileManifestEntry) -> String {
        // Format one file entry line (UUID, name, size, etc.)
        return "\(file.uuid.uuidString)\t\(file.fileName)\t\(file.size) bytes\t\(file.modificationDate)"
    }
    
    private func parseResponse(_ text: String) -> [(UUID, String)] {
        var suggestions: [(UUID, String)] = []
        let lines = text.split(separator: "\n")
        for line in lines {
            // Expect format "UUID -> FolderPath"
            if let arrowIndex = line.firstIndex(of: "→") ?? line.firstIndex(of: ">") {
                let uuidStr = line.prefix(upTo: arrowIndex).trimmingCharacters(in: .whitespacesAndNewlines, excluding: ["-", ">"])
                let dest = line.suffix(from: arrowIndex).replacingOccurrences(of: "->", with: "").trimmingCharacters(in: .whitespaces)
                if let uuid = UUID(uuidString: uuidStr), !dest.isEmpty {
                    suggestions.append((uuid, dest))
                }
            }
        }
        return suggestions
    }
}
```

*(Note: The above is illustrative pseudocode. In a real implementation,* *FoundationModel.generate* *might be an async call or require specific parameters, and the conversation context would handle the token counting. The parsing logic should be robust to the model’s actual output format.)*



Key points in this implementation:



- The planner uses a conversationContext to accumulate prompts. This could be as simple as concatenating strings or using a structured API if the Foundation Model supports chat messages.
- planChunk handles adding the chunk prompt and calling the model. If the calling code knows the token budget will be exceeded, it can pass a carryOverSummary and reset the context beforehand. Otherwise, it continues in the same context.
- resetSessionAndSummarize is used to end a session when needed. We derive a summary of the plan so far – here we collect the distinct top-level folders used so far (e.g. “Archive, Personal, Work”) and join them. This summary will be inserted into the next session’s prompt to give the model continuity  . We could make this smarter (include subfolder structure or other details as needed).
- The model output parsing looks for lines containing a UUID and a destination. We take care to trim and match the UUID format. This mapping of UUID -> FolderPath will feed into our OrganizationPlan.





With this planner, each chunk yields a list of suggestions. Now we need to aggregate those into the final plan.





## **Building the OrganizationPlan**





The FolderOrganizer.organizeDirectory method coordinates manifest building, chunk processing, and plan assembly:

```
func organizeDirectory(rootURL: URL, emitRestoreOnly: Bool) throws {
    // 1. Build file manifest and tag files
    let manifest = manifestBuilder.buildManifest(root: rootURL)
    // Also keep the original snapshots (from RestoreManager) if needed
    // (manifestBuilder could return both FileManifestEntry list and raw snapshots list)
    
    // 2. Split manifest into LLM-safe chunks
    let chunks = chunker.chunkManifest(manifest)
    
    var plan = OrganizationPlan()
    var carryOverSummary: String? = nil
    
    // 3. Iterate through chunks, get AI suggestions for each
    for (index, chunk) in chunks.enumerated() {
        // If adding this chunk would overflow token budget, reset the AI session
        if aiPlanner.estimatedTokensForChunk(chunk) + aiPlanner.currentSessionTokenCount > aiPlanner.tokenBudget {
            // Summarize the plan so far and reset session with that context
            carryOverSummary = aiPlanner.resetSessionAndSummarize(plan: plan)
        }
        // Get suggestions from AI for this chunk (provide summary if we carried one)
        let suggestions = try aiPlanner.planChunk(chunk, carryOverSummary: carryOverSummary)
        carryOverSummary = nil  // reset carryOver after use
        
        // 4. Integrate suggestions into the overall plan
        for (fileID, newPath) in suggestions {
            plan.addMove(fileID: fileID, newRelativePath: newPath)
        }
        // If any file in this chunk did not receive a suggestion (should not happen if prompt is clear), handle it (e.g., assign to "Uncategorized/").
    }
    
    // 5. At this point, `plan` contains the intended new location for every file.
    // If dry-run, we won't apply moves, but will still proceed to generate restore snapshot.
    
    // 6. If not a dry run, execute the planned moves on disk.
    if !emitRestoreOnly {
        for entry in manifest {
            if let newRelPath = plan.plannedMoves[entry.uuid] {
                let srcURL = entry.url
                let dstURL = rootURL.appendingPathComponent(newRelPath)
                // Create target directory if needed
                try FileManager.default.createDirectory(at: dstURL.deletingLastPathComponent(), 
                                                       withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: srcURL, to: dstURL)
            }
        }
    }
    
    // 7. In all cases, produce a restore snapshot using RestoreManager.
    //    We use the original manifest (with original paths) to log where files came from.
    RestoreManager.createRestoreFile(at: rootURL, snapshots: /* original snapshots list */)
    // If emitRestoreOnly, this file represents a "fake" snapshot (no moves were actually done).
    // If not emitRestoreOnly, this snapshot is the real record needed to restore later.
}
```

Let’s break down some important aspects of the above logic:



- We first obtain manifest as an array of FileManifestEntry. This inherently tags all files with UUIDs via RestoreManager.tagAllFilesInTree inside buildManifest . We also retain the original list of FileSnapshots (or we could reconstruct it from manifest) because we’ll need it for the restore file generation.

- The manifest is chunked by ManifestChunker. Each chunk is an independent list of entries to feed to the model.

- We iterate through the chunks, using AIReorganizationPlanner to process each. We check token budgets before each chunk:

  

  - If the next chunk might overflow the model’s context, we call resetSessionAndSummarize to start a fresh model session with a summary of the plan so far. The returned summary (a string of categories) is passed as carryOverSummary to planChunk.
  - If it’s safe to continue in the same session (e.g., the first few chunks might fit under the limit), we call planChunk with carryOverSummary: nil to continue the conversation directly.

  

- The AI returns suggestions as an array of (UUID, newPath) for that chunk’s files. We add each suggestion into the OrganizationPlan via plan.addMove. By the end of all chunks, plan.plannedMoves should have an entry for every file’s UUID.

  

  - **Error handling:** In practice, we’d include checks: if any file is missing in the suggestions (the model failed to provide a mapping), we could detect it by comparing plan.plannedMoves.keys against the manifest’s UUIDs. We might then assign those missing files to a default folder or re-prompt the model. The prompt is crafted to ask for every file, so ideally this doesn’t happen.
  - The design ensures consistency: if the model suggests the same folder for files across different chunks (e.g., “Work/Docs”), our plan simply collects those. If the model invents a new category in a later chunk, that’s fine – it gets added to the plan as well. Because we provide the model with prior categories (via context or summary), it’s likely to reuse them when appropriate, resulting in a coherent overall organization.

  

- After building the plan, we move into the execution phase. If emitRestoreOnly is true (dry-run), **we skip the actual file moves**. The plan is built and we will still generate a restore snapshot for the hypothetical moves.

- If it’s a real run, we loop through each file in the manifest, find its planned new path in the plan, and perform the move:

  

  - We use FileManager to create the target directory (including intermediate folders) if it doesn’t exist.
  - Then move the file from its current location (entry.url, which is still the original location at this moment, since we haven’t moved yet) to the new location.
  - We rely on the fact that entry.url still points to the original file (because we haven’t modified the manifest list). It’s important that we move each file in a way that doesn’t interfere with subsequent moves. If the new directory structure overlaps with the old (unlikely, since usually we’re sorting into new subfolders), we might want to ensure we don’t move a parent directory into its child, etc. But since we process file by file, it should be fine. The restore mechanism can also clean up any empty folders left behind later (the restoreFromSnapshot calls cleanupEmptyDirectories after restoring  ).

  

- Finally, we create a restore snapshot. We call RestoreManager.createRestoreFile(at: rootURL, snapshots: originalSnapshots). The originalSnapshots list contains each file’s original relative path and UUID (from before any moves) . The createRestoreFile method writes a Markdown file (e.g. .restore-20250620-161500.md) in the root directory, listing all files by **UUID and original path**  . It’s essentially a log of where each file came from. The file is then locked (immutable) to prevent accidental deletion  .

  

  - If this was a dry-run, we have not moved any files, but we still produce this snapshot as a **fake restore plan**. It shows what the restore file *would* look like if the reorganization had been executed. (Since no files moved, if someone actually tried to restore using it immediately, it would just find all files already in place and do nothing – which is fine. The primary purpose in dry-run is to show the user the mapping of original locations in case they want to inspect or save it.)
  - In a real run, this restore file is critical for enabling reversal. To undo the reorganization, the user (or program) can call RestoreManager.restoreFromSnapshot(rootURL:). The restoreFromSnapshot logic will read that Markdown, parse the list of UUIDs to original paths, scan the current directory tree for files with those UUIDs, and move each one back to its original location  . Thanks to the UUID tags, the restore process finds each file no matter which folder it was moved to. Any files already in the correct original spot are skipped , and any needed directories are created on the fly before moving the file back  . This means our entire reorganization can be **reversed in one go** with total accuracy.

  





Importantly, because we used RestoreManager.tagAllFilesInTree at the start, we did not have to individually log each move. The combination of *“all files have UUIDs”* and *“one restore snapshot with original paths”* achieves full tracking. Each move operation is implicitly recorded by virtue of the UUID staying with the file and the original path being saved in the snapshot. Thus, *every move is trackable and reversible*.



**Correctness & Safety:** This design ensures correctness at multiple levels:



- The chunking and session control prevent token overflow errors with the AI model.
- The restore snapshot guarantees that even if the program crashes or is stopped mid-way, any files moved up to that point still have their original paths recorded (since we generate the snapshot from the original manifest). We might generate the restore file at the end once all moves succeed; an improvement could be to write incremental data or use transactions. However, since we tag all files up front, even if a move happened without being recorded, a subsequent tagAllFilesInTree could still recover the mapping (because the file retains its UUID and we know its original path from initial snapshot).
- Moves are executed only after the full plan is ready, and we can validate the plan (e.g., ensure no two files target the exact same path causing a conflict, handle naming collisions by adjusting if needed, etc.). This can be built into the OrganizationPlan – for example, detect if two distinct files were both suggested to go to “Photos/IMG001.jpg” (same name in same folder) and resolve by maybe appending an index or skipping one. The extensible design allows adding such checks easily.
- The RestoreManager integration means the user can always roll back. The .restore.md snapshot file is human-readable (listing each file’s name, UUID, original path, etc.) and also machine-readable for the restore function. By not touching the files in dry-run, and by locking the restore file in real runs, we minimize risk of accidental changes.







## **RestoreManager Integration Points**





To clarify where and how the RestoreManager is used in this unified system:



- **Before AI processing:** RestoreManager.tagAllFilesInTree(rootURL:) is invoked at the very start of organizeDirectory. This tags files and provides the list of FileSnapshot objects (which we convert to our manifest entries)  . This is the only pass needed to assign UUIDs; the rest of the system can then use those UUIDs freely.
- **After planning, before execution:** (Optional) We could create a homogeneous snapshot here via RestoreManager.createHomogeneousSnapshot to save the baseline state of all files (it’s similar to restore file, but perhaps meant as a reference)  . This might not be necessary in normal operation, but it’s a safeguard copy of original mapping.
- **After execution (or dry-run):** We call RestoreManager.createRestoreFile(at:rootURL, snapshots: originalSnapshots) to generate the restore Markdown file  . We provide the **original** snapshots list (from before moves). The content of this file is a mapping from each file’s UUID to its original path. Note that we intentionally do **not** update the originalPath after moving — the snapshots remain as they were. That’s exactly what we want in the restore file: the original locations. The new locations aren’t explicitly recorded in the snapshot; instead, at restore time the manager finds the new location by searching for the file’s UUID in the current tree . This design means we don’t even have to know or save where the file was moved *to* — the file itself carries that information via the UUID in its metadata.
- **During restore (outside our reorg function):** If the user invokes a restore, RestoreManager.restoreFromSnapshot will parse the latest .restore.md file and execute the reverse moves  . Because our reorganization process never touches the .restore.md files (we even skip them in scanning ), and we lock them as immutable after creation , the restore records remain safe and intact.





**When to call RestoreManager:** In our FolderOrganizer.organizeDirectory, the calls to RestoreManager happen at:



- Start: tagAllFilesInTree (get snapshots and tag files).
- End: createRestoreFile (output snapshot).





We do **not** need to call any RestoreManager function for each individual move. However, for transparency, we might log each move in console or UI as it happens (e.g., “Moving file X to Y…”), but the restore mechanism doesn’t require per-move calls. The heavy lifting is all in the snapshot creation and the eventual restore scanning by UUID.



If we wanted to extend RestoreManager to track moves in real-time (for example, to generate a mapping of old→new paths), we could. But the current restore approach doesn’t actually need to know the new path; it finds it dynamically. This is a clever design: it reduces the bookkeeping needed during the move operations.





## **Execution Safety and Dry-Run Mode**





Finally, the system distinguishes between a **real execution** and a **dry-run (emitRestoreOnly)**:



- In **real execution**, after obtaining the OrganizationPlan, the system goes through with moving files on disk. It uses the plan’s information to create directories and move files with FileManager. All moves should be done carefully:

  

  - Use FileManager.moveItem(at:to:) which will fail if something exists at the destination. We may want to handle that by removing any placeholder file at the target (in case a file accidentally already exists with the same name) or by renaming. The restore file allows recovering even if some collisions occurred and were overwritten, but it’s better to avoid unexpected overwrites. An extensible design could incorporate a conflict-resolution strategy in the plan execution.
  - We should execute moves one by one, and potentially catch errors to continue moving the rest (so that a single failure doesn’t abort the entire process). Any failures can be reported to the user. Those failed files would remain in their original location (and would also be listed as such in the restore file, since we used the original snapshot), so they effectively wouldn’t move – which is consistent with the restore snapshot (it would simply restore nothing for them since they never left).
  - After all moves, the directory is reorganized as suggested. We then produce the restore snapshot (which we did in the code above). The system can print/log a success message and the location of the restore file (which might be named with a timestamp, e.g. .restore-20250620-160500.md).

  

- In **dry-run execution** (emitRestoreOnly = true), the steps until plan creation are the same, but the actual FileManager.moveItem calls are skipped. Instead:

  

  - We still call RestoreManager.createRestoreFile with the original snapshots. This generates a **restore snapshot file** even though no moves occurred. We might want to communicate to the user that this is a simulated snapshot. The content of the snapshot will list all files and their original locations (just like a normal run). If the user tried to use it to restore immediately, it would do nothing (since files are already at original paths). However, the snapshot is essentially a plan for restoration *if* the moves had been done according to our AI plan.

  - We can output or display the planned moves in a user-friendly way. For example, since in dry-run the user might want to see what *would* happen, we could generate a report like:

    

    - file1.txt -> Organized/Work/Documents/file1.txt

    - photo.jpg -> Organized/Personal/Photos/2020/photo.jpg

    - etc.

      This is not explicitly part of the question’s requirement, but it would be a reasonable addition to improve clarity. The OrganizationPlan can easily be used to produce such a list by comparing each file’s original path to its new path. In the current design, we focused on the restore snapshot (which is somewhat indirect for preview purposes), but an extensible system might include a function to output the direct move mapping as well.

    

  - No changes to user files are made in dry-run. After generating the restore snapshot (and any logs), the function would end. The user can inspect the .restore.md file if they want to verify the list of files and their original locations (knowing that, had the move occurred, those original locations are what the snapshot restores to).

  





To illustrate, here’s how we might augment the dry-run handling to print the plan for clarity (optional):

```
if emitRestoreOnly {
    print("Dry-run complete. Proposed moves:")
    for entry in manifest {
        if let newRelPath = plan.plannedMoves[entry.uuid] {
            print(" - \(entry.originalPath) -> \(newRelPath)")
        }
    }
    print("No files were moved. A restore snapshot has been generated for review.")
}
```

This way, the user sees exactly what the plan entails without actually applying it.





## **Extensibility Considerations**





This redesigned system is built with future extensions in mind:



- **Changing the Model or Prompting Strategy:** The AIReorganizationPlanner is isolated from the rest of the code, so we can easily swap in a different model or adjust the prompt without affecting manifest building or execution. For instance, if we integrate a newer Foundation Model with a larger token context, we could adjust tokenBudget and maybe reduce or eliminate chunking.
- **Content Analysis Enhancements:** Currently, the manifest uses basic metadata (name, size, dates). We could extend ManifestBuilder to include file content previews for certain types (e.g., extract the title from documents, or the subject from emails, etc.) to give the AI more context. We would just add a field to FileManifestEntry and include it in the formatted prompt line. The chunker would automatically account for the extra tokens. The rest of the system (planner, plan assembly) remains unchanged.
- **Partial Execution and Resume:** Because we rely heavily on the restore snapshot (which encapsulates the original state), we could allow the system to be stopped and resumed. For example, if organizing a massive directory, one could chunk through part of it, write intermediate results, and continue. As long as the final restore snapshot is eventually written for all files, the operation can be recovered. We might also create restore snapshots incrementally after each chunk’s moves in a future version for even safer operation.
- **Undoing Specific Moves or Iterative Refinement:** With every file tagged and a central plan, a future feature could let the user accept or reject certain AI suggestions before execution. For instance, present the OrganizationPlan (perhaps group by target folder) for review, allow edits, then apply. The design’s separation of plan computation and execution facilitates this – the OrganizationPlan is a clear contract of what will happen and can be manipulated independently of the AI and restore logic.
- **Multi-step Organization or Categorization Rules:** The system could be extended to support user-defined rules or additional AI passes (for example, first classify files by type, then within type by date). The modular design allows plugging in new stages – e.g., one could add a preprocessing step that groups files by extension and feeds that info into the AI prompt.



​	

In summary, this cohesive system efficiently combines AI-driven planning with a rock-solid restore mechanism. It builds a complete picture of the file tree, uses chunked AI sessions to organize files without overrunning model limits, and keeps track of every file via UUID. The RestoreManager ensures that for every organization operation, there’s a reliable snapshot to undo it. The classes and functions are organized to be easily maintainable and extensible, enabling future improvements with minimal changes to the overall structure. This design prioritizes correctness (through careful tracking and token management), clarity (clear separation of concerns and straightforward data flows), and extensibility (ability to modify components in isolation or add new features). With this in place, the folder organization tool becomes powerful, safe, and adaptable to various use cases.
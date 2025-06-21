import Foundation
import AppIntents
import SwiftUI

@available(macOS 26.0, *)
@MainActor
struct OrganizeFilesIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Organize Files"
    nonisolated static let description = IntentDescription("Organize files in a directory using Apple Intelligence")

    @Parameter(title: "Directory")
    var directory: URL

    func perform() async throws -> some IntentResult {
        let manager  = FoundationModelsManager()
        await manager.initialize()
        let processor = FileProcessor(foundationModelsManager: manager)
        let result = try await processor.processDirectory(directory)
        return .result(dialog: IntentDialog("Organized \(result.filesOrganized) files into \(result.categoriesCreated.count) categories"))
    }
}

// TODO: Re-enable snippet intent when OrganizationResult conforms to _IntentValue
// @available(macOS 26.0, *)
// @MainActor
// struct OrganizationSnippetIntent: SnippetIntent {
//     nonisolated static let title: LocalizedStringResource = "Organization Results"
//
//     @Parameter var result: OrganizationResult
//
//     func perform() async throws -> some IntentResult & ShowsSnippetView {
//         return .result(view: OrganizationResultSnippetView(result: result))
//     }
// }

@available(macOS 26.0, *)
struct OrganizationResultSnippetView: View {
    let result: OrganizationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .foregroundColor(.accentColor)
                Text("Organization Complete")
                    .font(.headline)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("\(result.filesProcessed)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Files Organized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(result.categoriesCreated.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Button(intent: ViewInAppIntent()) {
                    Label("Open App", systemImage: "arrow.right")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

@available(macOS 26.0, *)
@MainActor
struct ViewInAppIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Open App"

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

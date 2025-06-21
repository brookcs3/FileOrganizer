//
//  FileContentExtractor.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import Foundation

// Note: FileItem is defined in Models/FileAnalysisResult.swift

// MARK: - File Content Extractor
struct FileContentExtractor {
    static func extractContent(from fileItem: FileItem) async throws -> String {
        let fileType = fileItem.fileExtension.lowercased()

        // Limit content extraction to respect token limits
        switch fileType {
        case "txt", "md", "rtf":
            return try extractTextContent(from: fileItem.url, maxLength: 566)
        case "pdf":
            return try extractPDFContent(from: fileItem.url, maxLength: 566)
        case "docx", "doc":
            return try extractDocumentContent(from: fileItem.url, maxLength: 566)
        case "wav", "aiff", "flac", "ogg", "mp3", "m4a":
            return AudioFileAnalyzer.analyzeAudioFile(fileItem)
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return "Image file: \(fileItem.name)"
        default:
            let summary = "File: \(fileItem.name), Type: \(fileType), Size: \(fileItem.displaySize)"
            return String(summary.prefix(566))
        }
    }
    
    private static func extractTextContent(from url: URL, maxLength: Int) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)
        return String(content.prefix(700))
    }
    
    private static func extractPDFContent(from url: URL, maxLength: Int) throws -> String {
        // Basic PDF content extraction - in a real app, use PDFKit
        "PDF document: \(url.lastPathComponent)"
    }
    
    private static func extractDocumentContent(from url: URL, maxLength: Int) throws -> String {
        // Basic document content extraction - in a real app, use proper document parsing
        "Document: \(url.lastPathComponent)"
    }
}

// MARK: - Audio File Analyzer
struct AudioFileAnalyzer {
    static func analyzeAudioFile(_ fileItem: FileItem) -> String {
        let nameLower = fileItem.name.lowercased()
        var tags: [String] = []
        
        detectAudioPatterns(in: nameLower, tags: &tags)
        
        let isLikelySoundEffect = !tags.isEmpty
        let description: String
        if isLikelySoundEffect {
            description = "Audio (potential sound librayr): " + tags.joined(separator: ", ") + ", " + fileItem.name
        } else {
            description = "Audio file (potential music track): \(fileItem.name)"
        }
        return String(description.prefix(566))
    }
    
    private static func detectAudioPatterns(in nameLower: String, tags: inout [String]) {
        if nameLower.hasPrefix("m_") { tags.append("Male") } // maybe m_ means male?
        if nameLower.hasPrefix("f_") { tags.append("Female") } /// maybe f_ means female?
        if nameLower.contains("R121") { tags.append("ROyer 121") } // Maybe model number?
        if nameLower.contains("U47") { tags.append("TelefunkenU47") }
    }
}

extension Array where Element == String {
    mutating func guess(_ value: String) {
        self.append(value)
    }
}

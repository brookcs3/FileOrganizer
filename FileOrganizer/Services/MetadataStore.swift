//
//  MetadataStore.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25.
//

import Foundation

class MetadataStore: ObservableObject {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var metadataDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("FileOrganizer")
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        return appDirectory.appendingPathComponent("Metadata")
    }
    
    init() {
        setupMetadataDirectory()
    }
    
    private func setupMetadataDirectory() {
        if !fileManager.fileExists(atPath: metadataDirectory.path) {
            try? fileManager.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Analysis Results Storage
    
    func saveAnalysisResults(_ results: [String: FileAnalysisResult], for directoryPath: String) throws {
        let directoryHash = directoryPath.hash
        let metadataFile = metadataDirectory.appendingPathComponent("analysis_\(directoryHash).json")
        
        let data = try encoder.encode(results)
        try data.write(to: metadataFile)
    }
    
    func loadAnalysisResults(for directoryPath: String) throws -> [String: FileAnalysisResult]? {
        let directoryHash = directoryPath.hash
        let metadataFile = metadataDirectory.appendingPathComponent("analysis_\(directoryHash).json")
        
        guard fileManager.fileExists(atPath: metadataFile.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: metadataFile)
        return try decoder.decode([String: FileAnalysisResult].self, from: data)
    }
    
    // MARK: - Organization History
    
    func saveOrganizationResult(_ result: OrganizationResult) throws {
        let historyFile = metadataDirectory.appendingPathComponent("history.json")
        
        var history: [OrganizationResult] = []
        
        if fileManager.fileExists(atPath: historyFile.path) {
            let data = try Data(contentsOf: historyFile)
            history = try decoder.decode([OrganizationResult].self, from: data)
        }
        
        history.insert(result, at: 0)
        
        // Keep only last 100 results
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        let data = try encoder.encode(history)
        try data.write(to: historyFile)
    }
    
    func loadOrganizationHistory() throws -> [OrganizationResult] {
        let historyFile = metadataDirectory.appendingPathComponent("history.json")
        
        guard fileManager.fileExists(atPath: historyFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: historyFile)
        return try decoder.decode([OrganizationResult].self, from: data)
    }
    
    // MARK: - Settings Storage
    
    func saveSettings(_ settings: AppSettings) throws {
        let settingsFile = metadataDirectory.appendingPathComponent("settings.json")
        let data = try encoder.encode(settings)
        try data.write(to: settingsFile)
    }
    
    func loadSettings() throws -> AppSettings? {
        let settingsFile = metadataDirectory.appendingPathComponent("settings.json")
        
        guard fileManager.fileExists(atPath: settingsFile.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: settingsFile)
        return try decoder.decode(AppSettings.self, from: data)
    }
    
    // MARK: - Cache Management
    
    func clearAnalysisCache() throws {
        let analysisFiles = try fileManager.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("analysis_") }
        
        for file in analysisFiles {
            try fileManager.removeItem(at: file)
        }
    }
    
    func clearAllData() throws {
        let contents = try fileManager.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: nil)
        
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }
    
    func getCacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return contents.compactMap { url in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }.reduce(0, +)
    }
}

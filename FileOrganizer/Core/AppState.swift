//
//  AppState.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import SwiftUI
import Observation

@available(macOS 26.0, *)
@MainActor
@Observable
class AppState {
    var selectedDirectory: URL?
    var isProcessing = false
    var processingProgress: Double = 0.0
    var processingStatus = ""
    var lastOrganizationResult: OrganizationResult?
    var organizationHistory: [OrganizationResult] = []
    
    private let metadataStore = MetadataStore()

    func addToHistory(_ result: OrganizationResult) {
        organizationHistory.insert(result, at: 0)
        if organizationHistory.count > 50 {
            organizationHistory.removeLast()
        }
    }
    
    /// Loads organization history from persistent storage
    func loadHistory() async {
        do {
            organizationHistory = try metadataStore.loadOrganizationHistory()
        } catch {
            print("Failed to load history: \(error)")
        }
    }
    
    /// Saves organization result to persistent storage
    func saveResult(_ result: OrganizationResult) {
        do {
            try metadataStore.saveOrganizationResult(result)
        } catch {
            print("Failed to save result: \(error)")
        }
    }
}
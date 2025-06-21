//
//  DirectoryPickerService.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/21/25.
//

import SwiftUI
import AppKit

/// Service for handling directory selection and bookmarking
struct DirectoryPickerService {
    /// Shows the directory picker and returns selected URL
    static func selectDirectory() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a folder to organize"

        if openPanel.runModal() == .OK,
           let selectedURL = openPanel.url {
            return createBookmarkAndReturn(selectedURL)
        }
        return nil
    }
    
    /// Creates a security bookmark for the URL and returns it
    private static func createBookmarkAndReturn(_ selectedURL: URL) -> URL {
        do {
            let bookmark = try selectedURL.bookmarkData(
                options: .withSecurityScope
            )
            UserDefaults.standard.set(
                bookmark,
                forKey: "selectedFolderBookmark"
            )
            return selectedURL
        } catch {
            print("Failed to create bookmark: \(error)")
            return selectedURL
        }
    }
}

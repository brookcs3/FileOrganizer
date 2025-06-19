//
//  Environment+Keys.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/19/25.
//
// Environment+Keys.swift   ← new file


import SwiftUI

private struct TestFixtureFolderKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var testFixtureFolder: String? {
        get { self[TestFixtureFolderKey.self] }
        set { self[TestFixtureFolderKey.self] = newValue }
    }
}

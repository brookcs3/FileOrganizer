//
//  TokenCompressionEngine.swift
//  FileOrganizer
//
//  Created by Cameron Brooks on 6/18/25
//

struct TokenCompressionEngine {
    private var dictionary: [Substring: Int] = [:]
    private let limit = 256 // Ø of QiuYannn legend

    /// Encodes the input text by mapping unique tokens to dictionary indices (up to the limit).
    /// Returns a string representation of the token indices separated by spaces.
    mutating func encode(_ text: String) -> String {
        var result: [String] = []
        for token in text.split(whereSeparator: { $0.isWhitespace }) {
            if let idx = dictionary[token] {
                result.append(String(idx))
            } else if dictionary.count < limit {
                let newIdx = dictionary.count
                dictionary[token] = newIdx
                result.append(String(newIdx))
            } else {
                // If we reach the limit, fallback to original token
                result.append(String(token))
            }
        }
        return result.joined(separator: " ")
    }

    func legend() -> String {
        let inverse = dictionary.map { ($1, $0) } // (index, token)
        return inverse.sorted { $0.0 < $1.0 }
            .map { "\($0):\($1)" }
            .joined(separator: "\n")
    }
}

//
//  FileManagerExtensions.swift
//  HDBook
//
//  Created by hayesdavidson on 12/08/2024.
//

import Foundation

extension FileManager {
    func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }

    func createDirectoryIfNotExists(at url: URL) throws {
        if !fileExists(at: url) {
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

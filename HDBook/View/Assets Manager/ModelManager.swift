//
//  ModelManager.swift
//  HDBook
//
//  Created by hayesdavidson on 24/07/2024.
//

import Foundation
import RealityKit

class ModelManager: ModelManagement {
    func loadModel(from url: URL) throws -> ModelEntity {
        let entity = try ModelEntity.loadModel(contentsOf: url)
        return entity
    }
}


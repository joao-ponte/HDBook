//
//  ModelManager.swift
//  HDBook
//
//  Created by hayesdavidson on 24/07/2024.
//

import Foundation
import RealityKit

class ModelManager: ModelManagement {
    func loadModel(named modelName: String) async throws -> ModelEntity {
        guard let modelURL = FirebaseStorageService.shared.getLocalModelURL(for: modelName) else {
            throw NSError(domain: "ModelManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        let entity = try await ModelEntity.loadModel(contentsOf: modelURL)
        return entity
    }
}

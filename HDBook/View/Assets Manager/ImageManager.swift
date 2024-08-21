//
//  ImageManager.swift
//  HDBook
//
//  Created by hayesdavidson on 24/07/2024.
//

import UIKit

class ImageManager: ImageManagement {
    func createPanoramaView(for image360URL: URL, frame: CGRect) -> CTPanoramaView? {
        guard let image = UIImage(contentsOfFile: image360URL.path) else {
            print("Failed to load image from \(image360URL.path)")
            return nil
        }
        let panoramaView = CTPanoramaView(frame: frame, image: image)
        panoramaView.controlMethod = .both
        return panoramaView
    }
}

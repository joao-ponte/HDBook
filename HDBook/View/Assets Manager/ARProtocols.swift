//
//  ARProtocols.swift
//  HDBook
//
//  Created by hayesdavidson on 24/07/2024.
//

import ARKit
import RealityKit

protocol ARSessionManagement {
    func configureARView(_ arView: ARView) async
    func resumeARSession() async
    func pauseARSession()
    func removeAllAnchors() async
}

protocol ARImageHandling {
    func handleImageAnchor(_ imageAnchor: ARImageAnchor)
    func placeImage360Screen(panoramaView: CTPanoramaView, imageAnchor: ARImageAnchor)
}

protocol ARVideoHandling {
    func placeVideoScreen(videoScreen: ModelEntity, imageAnchor: ARImageAnchor, uuid: UUID)
    func handleTrackingTimeout(for uuid: UUID)
    func startTrackingTimer(for uuid: UUID)
}

protocol ARModelHandling {
    func handleModelAsset(modelURL: URL, imageAnchor: ARImageAnchor, referenceImageName: String)
    func placeModel(modelEntity: ModelEntity, imageAnchor: ARImageAnchor)
}

protocol VideoManagement {
    var videoPlayers: [UUID: AVPlayer] { get set }
    func createVideoScreen(width: Float, height: Float, url: URL, uuid: UUID) -> ModelEntity
    func createVideoItem(with url: URL) -> AVPlayerItem
    func createVideoMaterial(with videoItem: AVPlayerItem, uuid: UUID) -> VideoMaterial
}

protocol ImageManagement {
    func createPanoramaView(for image360URL: URL, frame: CGRect) -> CTPanoramaView?
}

protocol ModelManagement {
    func loadModel(from url: URL) throws -> ModelEntity
}

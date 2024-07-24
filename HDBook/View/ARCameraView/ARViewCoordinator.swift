//
//  ARViewCoordinator.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import RealityKit
import ARKit
import AVKit

class ARViewCoordinator: NSObject, ARSessionDelegate, ObservableObject {
    var arView: ARView?
    var videoAnchors: [UUID: Date] = [:]
    var videoPlayers: [UUID: AVPlayer] = [:]
    var videoURLs: [UUID: URL] = [:] // Add this dictionary to store video URLs
    var activeAnchors: [UUID: AnchorEntity] = [:]
    private var trackingTimers: [UUID: Timer] = [:]
    private var activeAnchor: AnchorEntity?

    @Published var is360ViewActive = false
    private var firebaseStorageService: FirebaseStorageService

    init(firebaseStorageService: FirebaseStorageService) {
        self.firebaseStorageService = firebaseStorageService
    }

    func configureARView(_ arView: ARView) async {
        self.arView = arView
        await arView.session.delegate = self
        do {
            let configuration = try createARConfiguration()
            await arView.session.run(configuration)
        } catch {
            print("Failed to configure ARView: \(error)")
        }
    }

    func resumeARSession() async {
        guard let arView = arView else { return }
        do {
            let configuration = try createARConfiguration()
            await arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("AR session resumed.")
        } catch {
            print("Failed to resume AR session: \(error)")
        }
    }

    func pauseARSession() {
        arView?.session.pause()
        print("AR session paused.")
    }

    func pauseAllVideoPlayers() {
        for player in videoPlayers.values {
            player.pause()
        }
        print("All video players paused.")
    }

    func resumeAllVideoPlayers() {
        for player in videoPlayers.values {
            player.play()
        }
        print("All video players resumed.")
    }

    func removeAllAnchors() async {
        if let anchor = activeAnchor {
            await arView?.scene.removeAnchor(anchor)
        }
        activeAnchor = nil
    }

    private func createARConfiguration() throws -> ARImageTrackingConfiguration {
        let configuration = ARImageTrackingConfiguration()
        let referenceImages = firebaseStorageService.getARReferenceImages()
        configuration.trackingImages = Set(referenceImages)
        configuration.maximumNumberOfTrackedImages = 1
        return configuration
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard !is360ViewActive else { return }
        
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                handleImageAnchor(imageAnchor)
            }
        }
    }

    private func handleImageAnchor(_ imageAnchor: ARImageAnchor) {
        let uuid = imageAnchor.identifier
        videoAnchors[uuid] = Date()

        guard let referenceImageName = imageAnchor.referenceImage.name else {
            print("Failed to get reference image name.")
            return
        }

        print("Image anchor detected: \(referenceImageName)")

        let videoURL = firebaseStorageService.videosDirectory
            .appendingPathComponent(String(referenceImageName.split(separator: ".").first ?? ""))
            .appendingPathExtension("mp4")
        
        let image360URL = firebaseStorageService.images360Directory
            .appendingPathComponent(String(referenceImageName.split(separator: ".").first ?? ""))
            .appendingPathExtension("jpg")

        if FileManager.default.fileExists(atPath: videoURL.path) {
            videoURLs[uuid] = videoURL // Store the video URL

            if let arView = arView {
                let videoScreen = createVideoScreen(width: Float(imageAnchor.referenceImage.physicalSize.width), height: Float(imageAnchor.referenceImage.physicalSize.height), url: videoURL, uuid: uuid)
                placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor, uuid: uuid)
                print("Playing video for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil.")
            }
        } else if FileManager.default.fileExists(atPath: image360URL.path) {
            if let arView = arView, let image = UIImage(contentsOfFile: image360URL.path) {
                let panoramaView = CTPanoramaView(frame: arView.bounds, image: image)
                panoramaView.controlMethod = .both
                placeImage360Screen(panoramaView: panoramaView, imageAnchor: imageAnchor)

                is360ViewActive = true
                pauseARSession()
                print("Presenting 360 view for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil or failed to load image.")
            }
        } else {
            print("No valid asset found for tracked image: \(referenceImageName)")
        }
    }

    private func placeVideoScreen(videoScreen: ModelEntity, imageAnchor: ARImageAnchor, uuid: UUID) {
        guard let arView = arView else { return }

        let imageAnchorEntity = AnchorEntity(anchor: imageAnchor)
        let rotationAngle = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: SIMD3(x: 1, y: 0, z: 0))
        videoScreen.setOrientation(rotationAngle, relativeTo: imageAnchorEntity)
        imageAnchorEntity.addChild(videoScreen)

        arView.scene.addAnchor(imageAnchorEntity)
        activeAnchors[uuid] = imageAnchorEntity

        startTrackingTimer(for: uuid)
        print("Video screen placed for UUID: \(uuid)")
    }

    private func createVideoScreen(width: Float, height: Float, url: URL, uuid: UUID) -> ModelEntity {
        let screenMesh = MeshResource.generatePlane(width: width, height: height)
        let videoItem = createVideoItem(with: url)
        let videoMaterial = createVideoMaterial(with: videoItem, uuid: uuid)
        let videoScreenModel = ModelEntity(mesh: screenMesh, materials: [videoMaterial])
        return videoScreenModel
    }

    private func createVideoItem(with url: URL) -> AVPlayerItem {
        let asset = AVURLAsset(url: url)
        let videoItem = AVPlayerItem(asset: asset)
        return videoItem
    }

    private func createVideoMaterial(with videoItem: AVPlayerItem, uuid: UUID) -> VideoMaterial {
        let player = AVPlayer()
        player.actionAtItemEnd = .none
        let videoMaterial = VideoMaterial(avPlayer: player)
        player.replaceCurrentItem(with: videoItem)
        player.play()

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        videoPlayers[uuid] = player
        print("Video material created for UUID: \(uuid)")
        return videoMaterial
    }

    private func startTrackingTimer(for uuid: UUID) {
        trackingTimers[uuid] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.handleTrackingTimeout(for: uuid)
        }
        print("Tracking timer started for UUID: \(uuid)")
    }

    private func handleTrackingTimeout(for uuid: UUID) {
        guard let anchor = activeAnchors[uuid], let player = videoPlayers[uuid] else { return }
        player.pause()
        arView?.scene.removeAnchor(anchor)
        activeAnchors.removeValue(forKey: uuid)
        videoPlayers.removeValue(forKey: uuid)
        trackingTimers.removeValue(forKey: uuid)
        print("Tracking timeout handled for UUID: \(uuid)")
    }

    // Session Did Update
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let currentTimestamp = Date()
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                let uuid = imageAnchor.identifier

                // Only proceed if this anchor is associated with a video or was previously associated with a video
                if let videoURL = videoURLs[uuid] {
                    videoAnchors[uuid] = currentTimestamp
                    if activeAnchors[uuid] == nil {
                        let videoScreen = createVideoScreen(width: Float(imageAnchor.referenceImage.physicalSize.width), height: Float(imageAnchor.referenceImage.physicalSize.height), url: videoURL, uuid: uuid)
                        placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor, uuid: uuid)
                    } else {
                        trackingTimers[uuid]?.invalidate()
                        startTrackingTimer(for: uuid)
                    }
                    if let referenceImageName = imageAnchor.referenceImage.name {
                        print("Tracking image: \(referenceImageName)")
                    }
                }
            }
        }

        // Check for any anchors that haven't been seen recently and handle timeout
        for (uuid, lastSeen) in videoAnchors {
            if currentTimestamp.timeIntervalSince(lastSeen) > 1 {
                handleTrackingTimeout(for: uuid)
            }
        }
    }

    private func stopAndRemoveAllVideoPlayers() {
        for (uuid, player) in videoPlayers {
            player.pause()
            player.replaceCurrentItem(with: nil)
            videoPlayers[uuid] = nil
        }
        videoPlayers.removeAll()
        print("All video players stopped and removed.")
    }

    private func placeImage360Screen(panoramaView: CTPanoramaView, imageAnchor: ARImageAnchor) {
        guard let arView = arView else { return }

        if let currentView = arView.subviews.first(where: { $0 is CTPanoramaView }) {
            currentView.removeFromSuperview()
        }

        arView.addSubview(panoramaView)

        activeAnchor = AnchorEntity(anchor: imageAnchor)
        arView.scene.addAnchor(activeAnchor!)
        print("360 image screen placed for image anchor: \(imageAnchor.referenceImage.name ?? "")")
    }

    func exit360View() {
        is360ViewActive = false
        removePanoramaView()
        Task {
            await resumeARSession()
        }
        print("Exited 360 view.")
    }

    private func removePanoramaView() {
        guard let arView = arView else { return }

        if let panoramaView = arView.subviews.first(where: { $0 is CTPanoramaView }) {
            panoramaView.removeFromSuperview()
        }
        print("Panorama view removed.")
    }
}

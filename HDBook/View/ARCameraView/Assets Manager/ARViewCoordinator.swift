//
//  ARViewCoordinator.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import RealityKit
import ARKit

class ARViewCoordinator: NSObject, ARSessionDelegate, ObservableObject, ARSessionManagement, ARImageHandling, ARVideoHandling {
    
    var arView: ARView?
    var videoAnchors: [UUID: Date] = [:]
    var videoURLs: [UUID: URL] = [:]
    var activeAnchors: [UUID: AnchorEntity] = [:]
    private var trackingTimers: [UUID: Timer] = [:]
    private var activeAnchor: AnchorEntity?
    private var videoManager: VideoManager
    private var imageManager: ImageManager
    private var modelManager: ModelManagement
    
    @Published var is360ViewActive = false
    @Published var isSuperZoomPresented: Bool = false
    @Published var superZoomURL: URL?
    
    private var firebaseStorageService: FirebaseStorageService
    
    init(firebaseStorageService: FirebaseStorageService, videoManager: VideoManager = VideoManager(), imageManager: ImageManager = ImageManager(), modelManager: ModelManagement = ModelManager()) {
        self.firebaseStorageService = firebaseStorageService
        self.videoManager = videoManager
        self.imageManager = imageManager
        self.modelManager = modelManager
    }
    
    // MARK: - ARSessionManagement
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
    
    // MARK: - ARImageHandling
    
    internal func handleImageAnchor(_ imageAnchor: ARImageAnchor) {
        let uuid = imageAnchor.identifier
        videoAnchors[uuid] = Date()
        
        guard let referenceImageName = imageAnchor.referenceImage.name else {
            print("Failed to get reference image name.")
            return
        }
        
        print("Image anchor detected: \(referenceImageName)")
        
        if referenceImageName.contains("_CIN") {
            handleVideoAsset(for: referenceImageName, imageAnchor: imageAnchor, uuid: uuid)
        } else if referenceImageName.contains("_360") {
            handle360ImageAsset(for: referenceImageName, imageAnchor: imageAnchor)
        } else if referenceImageName.contains("_ARM") {
            handle3DModelAsset(for: referenceImageName, imageAnchor: imageAnchor)
        } else if referenceImageName.contains("_SPZ") {  // Handling SuperZoom images
            handleSuperZoomAsset(for: referenceImageName, imageAnchor: imageAnchor)
        } else {
            print("No valid asset type found for tracked image: \(referenceImageName)")
        }
    }
    
    
    private func getVideoURL(for referenceImageName: String) -> URL? {
        let localVideoURL = firebaseStorageService.getLocalVideoURL(for: referenceImageName)
        return localVideoURL ?? firebaseStorageService.videosDirectory
            .appendingPathComponent(String(referenceImageName.split(separator: ".").first ?? ""))
            .appendingPathExtension("mp4")
    }
    
    private func getImage360URL(for referenceImageName: String) -> URL? {
        let localImage360URL = firebaseStorageService.getLocalImage360URL(for: referenceImageName)
        return localImage360URL ?? firebaseStorageService.images360Directory
            .appendingPathComponent(String(referenceImageName.split(separator: ".").first ?? ""))
            .appendingPathExtension("jpg")
    }
    
    private func get3DModelsURL(for referenceImageName: String) -> URL? {
        let local3DModelsURL = firebaseStorageService.getLocalModelURL(for: referenceImageName)
        print("Local 3D Model URL: \(String(describing: local3DModelsURL?.path))")
        
        guard let url = local3DModelsURL else {
            print("No valid 3D Model URL found for reference image: \(referenceImageName)")
            return nil
        }
        
        if FileManager.default.fileExists(atPath: url.path) {
            print("3D Model file exists at path: \(url.path)")
            return url
        } else {
            print("3D Model file does not exist at path: \(url.path)")
            return nil
        }
    }
    
    private func getSuperZoomURL(for referenceImageName: String) -> URL? {
        let localSuperZoomURL = firebaseStorageService.getLocalSuperZoomURL(for: referenceImageName)
        return localSuperZoomURL ?? firebaseStorageService.superZoomDirectory
            .appendingPathComponent(String(referenceImageName.split(separator: ".").first ?? ""))
            .appendingPathExtension("jpg")
    }
    
    
    private func handleVideoAsset(for referenceImageName: String, imageAnchor: ARImageAnchor, uuid: UUID) {
        guard let videoURL = getVideoURL(for: referenceImageName) else {
            print("No valid video asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: videoURL.path) {
            videoURLs[uuid] = videoURL
            let videoScreen = videoManager.createVideoScreen(width: Float(imageAnchor.referenceImage.physicalSize.width), height: Float(imageAnchor.referenceImage.physicalSize.height), url: videoURL, uuid: uuid)
            placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor, uuid: uuid)
            print("Playing video for image: \(referenceImageName)")
        } else {
            print("Video file does not exist at path: \(videoURL.path)")
        }
    }
    
    private func handle360ImageAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let image360URL = getImage360URL(for: referenceImageName) else {
            print("No valid 360 image asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: image360URL.path) {
            if let arView = arView, let panoramaView = imageManager.createPanoramaView(for: image360URL, frame: arView.bounds) {
                placeImage360Screen(panoramaView: panoramaView, imageAnchor: imageAnchor)
                is360ViewActive = true
                pauseARSession()
                print("Presenting 360 view for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil or failed to load image.")
            }
        } else {
            print("360 image file does not exist at path: \(image360URL.path)")
        }
    }
    
    private func handle3DModelAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let modelsURL = get3DModelsURL(for: referenceImageName) else {
            print("No valid 3D Models asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: modelsURL.path) {
            if let arView = arView {
                do {
                    print("Attempting to load model from URL: \(modelsURL)")
                    let modelEntity = try modelManager.loadModel(from: modelsURL)
                    place3DModel(modelEntity: modelEntity, imageAnchor: imageAnchor, uuid: imageAnchor.identifier)
                    print("Presenting 3D model for image: \(referenceImageName)")
                } catch {
                    print("Failed to load 3D model: \(error)")
                }
            } else {
                print("Error: ARView is nil.")
            }
        } else {
            print("3D model file does not exist at path: \(modelsURL.path)")
        }
    }
    
    private func handleSuperZoomAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let superZoomURL = getSuperZoomURL(for: referenceImageName) else {
            print("No valid SuperZoom asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: superZoomURL.path) {
            if let arView = arView {
                presentSuperZoomView(superZoomURL: superZoomURL)
                pauseARSession()
                print("Presenting SuperZoom view for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil.")
            }
        } else {
            print("SuperZoom image file does not exist at path: \(superZoomURL.path)")
        }
    }
    
    internal func placeImage360Screen(panoramaView: CTPanoramaView, imageAnchor: ARImageAnchor) {
        guard let arView = arView else { return }
        
        if let currentView = arView.subviews.first(where: { $0 is CTPanoramaView }) {
            currentView.removeFromSuperview()
        }
        
        arView.addSubview(panoramaView)
        
        activeAnchor = AnchorEntity(anchor: imageAnchor)
        arView.scene.addAnchor(activeAnchor!)
        print("360 image screen placed for image anchor: \(imageAnchor.referenceImage.name ?? "")")
    }
    
    // MARK: - ARVideoHandling
    
    internal func placeVideoScreen(videoScreen: ModelEntity, imageAnchor: ARImageAnchor, uuid: UUID) {
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
    
    internal func startTrackingTimer(for uuid: UUID) {
        trackingTimers[uuid] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.handleTrackingTimeout(for: uuid)
        }
        print("Tracking timer started for UUID: \(uuid)")
    }
    
    internal func handleTrackingTimeout(for uuid: UUID) {
        guard let anchor = activeAnchors[uuid], let player = videoManager.videoPlayers[uuid] else { return }
        player.pause()
        arView?.scene.removeAnchor(anchor)
        activeAnchors.removeValue(forKey: uuid)
        videoManager.videoPlayers.removeValue(forKey: uuid)
        trackingTimers.removeValue(forKey: uuid)
        print("Tracking timeout handled for UUID: \(uuid)")
    }
    
    internal func place3DModel(modelEntity: ModelEntity, imageAnchor: ARImageAnchor, uuid: UUID) {
        guard let arView = arView else { return }
        
        let imageAnchorEntity = AnchorEntity(anchor: imageAnchor)
        
        // Check if the model is the HDLogo_ARM and apply specific configuration
        if imageAnchor.referenceImage.name == "HDLogo_ARM" {
            // Set the model's position to be closer to the origin of the image anchor right/high/left
            modelEntity.setPosition(SIMD3<Float>(0.01, 0.05, 0), relativeTo: imageAnchorEntity)
            
            // Adjust the scale
            modelEntity.scale = [0.0075, 0.0075, 0.0075]
            
            // Apply rotation to the model around the x-axis
            let rotation = simd_quatf(angle: GLKMathDegreesToRadians(180), axis: SIMD3<Float>(1, 0, 0))
            modelEntity.setOrientation(rotation, relativeTo: imageAnchorEntity)
            
            print("HDLogo_ARM specific configuration applied.")
        } else {
            // Default configuration for other 3D models
            modelEntity.setPosition(SIMD3<Float>(0, 0, 0), relativeTo: imageAnchorEntity)
            modelEntity.scale = [0.10, 0.10, 0.10]
            
            print("Default configuration applied.")
        }
        
        imageAnchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(imageAnchorEntity)
        activeAnchors[uuid] = imageAnchorEntity
        
        startTrackingTimer(for: uuid)
        print("3D model placed for UUID: \(uuid)")
        print("Model entity's final position: \(modelEntity.position)")
    }
    
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let currentTimestamp = Date()
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                let uuid = imageAnchor.identifier
                
                if let videoURL = videoURLs[uuid] {
                    videoAnchors[uuid] = currentTimestamp
                    if activeAnchors[uuid] == nil {
                        let videoScreen = videoManager.createVideoScreen(width: Float(imageAnchor.referenceImage.physicalSize.width), height: Float(imageAnchor.referenceImage.physicalSize.height), url: videoURL, uuid: uuid)
                        placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor, uuid: uuid)
                    } else {
                        trackingTimers[uuid]?.invalidate()
                        startTrackingTimer(for: uuid)
                    }
                    if let referenceImageName = imageAnchor.referenceImage.name {
                        print("Tracking image: \(referenceImageName)")
                    }
                } else if activeAnchors[uuid] == nil {
                    // Handle newly detected anchors for 3D models and 360 images if needed
                }
            }
        }
        
        for (uuid, lastSeen) in videoAnchors {
            if currentTimestamp.timeIntervalSince(lastSeen) > 1 {
                handleTrackingTimeout(for: uuid)
            }
        }
    }
    
    // MARK: - Additional Functions
    
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
    
    func loadARReferenceImages() async {
        await firebaseStorageService.downloadFiles(progress: { progress in
            print("Download progress: \(progress)")
        })
        firebaseStorageService.createARReferenceImages()
        print("AR reference images loaded.")
    }
    
    private func list3DModelsDirectoryContents() {
        let fileManager = FileManager.default
        let modelsDirectoryPath = firebaseStorageService.modelsDirectory.path
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: modelsDirectoryPath)
            print("Contents of 3DModels directory:")
            for file in files {
                print(file)
            }
        } catch {
            print("Error reading contents of 3DModels directory: \(error)")
        }
    }
    
    func presentSuperZoomView(superZoomURL: URL) {
        self.superZoomURL = superZoomURL
        self.isSuperZoomPresented = true
        pauseARSession()
    }

    func exitSuperZoomView() {
        self.superZoomURL = nil
        self.isSuperZoomPresented = false
        Task {
            await resumeARSession()
        }
        print("Exited SuperZoom view.")
    }
}

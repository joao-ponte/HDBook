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
    @Published var isFilmPresented: Bool = false
    @Published var filmURL: URL?
    @Published var superZoomURL: URL?
    @Published var showAlert = false
    @Published var show360ViewAlert = false
    
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
        
        switch identifyAssetType(from: referenceImageName) {
        case .video:
            handleVideoAsset(for: referenceImageName, imageAnchor: imageAnchor, uuid: uuid)
        case .image360:
            handle360ImageAsset(for: referenceImageName, imageAnchor: imageAnchor)
        case .model:
            handle3DModelAsset(for: referenceImageName, imageAnchor: imageAnchor)
        case .superZoom:
            handleSuperZoomAsset(for: referenceImageName, imageAnchor: imageAnchor)
        case .film:
            handleFilmAsset(for: referenceImageName, imageAnchor: imageAnchor)
        case .web:
            handleWebAsset(for: referenceImageName, imageAnchor: imageAnchor)
        case .unknown:
            print("No valid asset type found for tracked image: \(referenceImageName)")
        }
    }
    
    private func identifyAssetType(from referenceImageName: String) -> AssetType {
        if referenceImageName.contains(Constants.videoSuffix) {
            return .video
        } else if referenceImageName.contains(Constants.image360Suffix) {
            return .image360
        } else if referenceImageName.contains(Constants.modelSuffix) {
            return .model
        } else if referenceImageName.contains(Constants.superZoomSuffix) {
            return .superZoom
        } else if referenceImageName.contains(Constants.filmSuffix) {
            return .film
        } else if referenceImageName.contains(Constants.webSuffix) {
            return .web
        } else {
            return .unknown
        }
    }
    
    private func getAssetURL(for referenceImageName: String, localURLProvider: (String) -> URL?, directory: URL, fileExtension: String) -> URL? {
        if let localURL = localURLProvider(referenceImageName) {
            return localURL
        } else {
            let fileName = String(referenceImageName.split(separator: ".").first ?? "")
            return directory.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        }
    }
    
    private func getVideoURL(for referenceImageName: String) -> URL? {
        return getAssetURL(
            for: referenceImageName,
            localURLProvider: firebaseStorageService.getLocalVideoURL,
            directory: firebaseStorageService.videosDirectory,
            fileExtension: Constants.videoExtension
        )
    }
    
    private func getImage360URL(for referenceImageName: String) -> URL? {
        return getAssetURL(
            for: referenceImageName,
            localURLProvider: firebaseStorageService.getLocalImage360URL,
            directory: firebaseStorageService.images360Directory,
            fileExtension: Constants.image360Extension
        )
    }
    
    private func get3DModelsURL(for referenceImageName: String) -> URL? {
        return getAssetURL(
            for: referenceImageName,
            localURLProvider: firebaseStorageService.getLocalModelURL,
            directory: firebaseStorageService.modelsDirectory,
            fileExtension: Constants.modelExtension
        )
    }
    
    private func getSuperZoomURL(for referenceImageName: String) -> URL? {
        return getAssetURL(
            for: referenceImageName,
            localURLProvider: firebaseStorageService.getLocalSuperZoomURL,
            directory: firebaseStorageService.superZoomDirectory,
            fileExtension: Constants.superZoomExtension
        )
    }
    
    private func getFilmURL(for referenceImageName: String) -> URL? {
        return getAssetURL(
            for: referenceImageName,
            localURLProvider: firebaseStorageService.getLocalFilmURL,
            directory: firebaseStorageService.filmsDirectory,
            fileExtension: Constants.filmExtension
        )
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
                show360ViewAlert = true
                pauseARSession()
                print("Presenting 360 view for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil or failed to load image.")
            }
        } else {
            print("360 image file does not exist at path: \(image360URL.path)")
        }
    }
    
    func dismiss360ViewAlert() {
        show360ViewAlert = false
    }
    
    private func handle3DModelAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let modelsURL = get3DModelsURL(for: referenceImageName) else {
            print("No valid 3D Models asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: modelsURL.path) {
            if arView != nil {
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
            if arView != nil {
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
    
    private func handleFilmAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let filmURL = getFilmURL(for: referenceImageName) else {
            print("No valid film asset found for tracked image: \(referenceImageName)")
            return
        }
        
        if FileManager.default.fileExists(atPath: filmURL.path) {
            if arView != nil {
                presentFilmView(filmURL: filmURL)
                print("Presenting film view for image: \(referenceImageName)")
            } else {
                print("Error: ARView is nil.")
            }
        } else {
            print("Film file does not exist at path: \(filmURL.path)")
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
    
    private func handleWebAsset(for referenceImageName: String, imageAnchor: ARImageAnchor) {
        guard let webAsset = Constants.WebAssets(rawValue: referenceImageName), let url = webAsset.url else {
            print("No valid web URL found for tracked image: \(referenceImageName)")
            return
        }
        
        if ConnectivityManager.isConnectedToInternet() {
            presentWebView(url: url)
        } else {
            print("No internet connection. Showing custom alert...")
            showAlert = true
        }
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
        
        if imageAnchor.referenceImage.name == "HDLogo_ARM" {
            // Specific configuration for HDLogo_ARM
            modelEntity.setPosition(SIMD3<Float>(0.01, 0.05, 0), relativeTo: imageAnchorEntity)
            modelEntity.scale = [0.0075, 0.0075, 0.0075]
            
            let rotation = simd_quatf(angle: GLKMathDegreesToRadians(180), axis: SIMD3<Float>(1, 0, 0))
            modelEntity.setOrientation(rotation, relativeTo: imageAnchorEntity)
            
            print("HDLogo_ARM specific configuration applied.")
            
            // Add the shadow-casting light to the scene
            let shadowCastingLight = createShadowCastingLight()
            imageAnchorEntity.addChild(shadowCastingLight)
            
            addShadowReceivingPlane(to: arView)
        } else {
            // Default configuration for other 3D models
            modelEntity.setPosition(SIMD3<Float>(0, 0, 0), relativeTo: imageAnchorEntity)
            modelEntity.scale = [0.15, 0.15, 0.15]
            
            print("Default configuration applied.")
        }
        
        imageAnchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(imageAnchorEntity)
        activeAnchors[uuid] = imageAnchorEntity
        
        startTrackingTimer(for: uuid)
        print("3D model placed for UUID: \(uuid)")
        print("Model entity's final position: \(modelEntity.position)")
    }
    
    private func createShadowCastingLight() -> Entity {
        let lightShineTarget = SIMD3<Float>(0, 0, 0)
        let lightPosition = SIMD3<Float>(3, 3, 1.5)
        
        // Create a directional light component
        var directionalLight = DirectionalLightComponent()
        directionalLight.intensity = 30000 // Adjust the intensity for shadow strength
//        directionalLight.color = .purple
        
        // Create an entity and attach the light component
        let lightEntity = Entity()
        lightEntity.position = lightPosition
        lightEntity.components[DirectionalLightComponent.self] = directionalLight
        
        // Rotate the light to shine toward the target
        lightEntity.look(at: lightShineTarget, from: lightPosition, relativeTo: nil)
        
        return lightEntity
    }
    
    private func addShadowReceivingPlane(to arView: ARView) {
        // Create a plane entity to receive shadows
        let planeSize: Float = 1  // Adjust size as needed
        let mesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        let material = OcclusionMaterial(receivesDynamicLighting: true)  // Plane receives shadows
        let shadowPlane = ModelEntity(mesh: mesh, materials: [material])

        // Position the plane at the origin, where you expect shadows to fall
        shadowPlane.position = [0, 0, 0]  // Place directly at the ground level

        // Create an anchor and add the plane to the scene
        let shadowPlaneAnchor = AnchorEntity(world: [0, 0, 0])
        shadowPlaneAnchor.addChild(shadowPlane)
        arView.scene.addAnchor(shadowPlaneAnchor)
    }

    private func presentWebViewConfirmation(url: URL) {
        let alert = UIAlertController(title: "Open Webpage", message: "Do you want to open this webpage?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { _ in
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                WebViewManager.presentWebView(url: url, in: viewController)
            }
        }))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
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
                }
            }
        }
        
        for (uuid, lastSeen) in videoAnchors {
            if let imageAnchor = anchors.compactMap({ $0 as? ARImageAnchor }).first(where: { $0.identifier == uuid }),
               let referenceImageName = imageAnchor.referenceImage.name {
                
                var timeoutInterval: TimeInterval = 1
                
                if referenceImageName.contains("_CIN") {
                    timeoutInterval = 1
                } else if referenceImageName.contains("_ARM") {
                    timeoutInterval = 30
                }
                
                if currentTimestamp.timeIntervalSince(lastSeen) > timeoutInterval {
                    handleTrackingTimeout(for: uuid)
                }
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
    
    func presentFilmView(filmURL: URL) {
        self.filmURL = filmURL
        self.isFilmPresented = true
        pauseARSession()
    }
    
    func exitFilmView() {
        self.filmURL = nil
        self.isFilmPresented = false
        Task {
            await resumeARSession()
        }
        print("Exited Film view.")
    }
    
    private func presentWebView(url: URL) {
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            WebViewManager.presentWebView(url: url, in: viewController)
        }
    }
    
    func dismissAlertAndResetARSession() {
        showAlert = false
        Task {
            await resetARSession()
        }
    }
    
    private func resetARSession() async {
        guard let arView = arView else { return }
        do {
            let configuration = try createARConfiguration()
            await arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("AR session reset after dismissing alert.")
        } catch {
            print("Failed to reset AR session: \(error)")
        }
    }
    
}

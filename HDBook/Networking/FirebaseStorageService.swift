//
//  FirebaseStorageService.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import FirebaseStorage
import UIKit
import ARKit

class FirebaseStorageService {
    private let storage: Storage
    let videosDirectory: URL
    let images360Directory: URL
    private let imagesDirectory: URL
    private(set) var arReferenceImages: [ARReferenceImage] = []

    static let shared = FirebaseStorageService()

    private init() {
        self.storage = Storage.storage()

        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Error: Failed to find document directory")
        }

        videosDirectory = documentDirectory.appendingPathComponent("Videos")
        images360Directory = documentDirectory.appendingPathComponent("360View")
        imagesDirectory = documentDirectory.appendingPathComponent("AR Images")

        createDirectory(at: videosDirectory)
        createDirectory(at: images360Directory)
        createDirectory(at: imagesDirectory)
        
        loadLocalARReferenceImages()
        createARReferenceImages()
    }

    private func createDirectory(at url: URL) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Created directory at: \(url.path)")
            } catch {
                print("Error creating directory: \(error)")
            }
        } else {
            print("Directory already exists at: \(url.path)")
        }
    }
    
    func loadLocalARReferenceImages() {
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) {
            arReferenceImages.append(contentsOf: referenceImages)
            print("Loaded local AR reference images.")
        } else {
            print("No local AR reference images found.")
        }
    }

    func getLocalVideoURL(for referenceImageName: String) -> URL? {
        return Bundle.main.url(forResource: referenceImageName, withExtension: "mp4", subdirectory: "Videos")
    }

    func getLocalImage360URL(for referenceImageName: String) -> URL? {
        return Bundle.main.url(forResource: referenceImageName, withExtension: "jpg", subdirectory: "360View")
    }

    func hasNewAssets() async throws -> Bool {
        let videoRef = storage.reference(withPath: "Videos")
        let image360Ref = storage.reference(withPath: "360View")
        let imageRef = storage.reference().child("AR Images")

        let localVideoFiles = try FileManager.default.contentsOfDirectory(atPath: videosDirectory.path)
        let localImage360Files = try FileManager.default.contentsOfDirectory(atPath: images360Directory.path)
        let localImageFiles = try FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)

        print("Local video files: \(localVideoFiles)")
        print("Local 360 image files: \(localImage360Files)")
        print("Local AR image files: \(localImageFiles)")

        let remoteVideoFiles = try await videoRef.listAll().items.map { $0.name }
        let remoteImage360Files = try await image360Ref.listAll().items.map { $0.name }
        let remoteImageFiles = try await imageRef.listAll().items.map { $0.name }

        print("Remote video files: \(remoteVideoFiles)")
        print("Remote 360 image files: \(remoteImage360Files)")
        print("Remote AR image files: \(remoteImageFiles)")

        let newVideoFiles = Set(remoteVideoFiles).subtracting(localVideoFiles)
        let newImage360Files = Set(remoteImage360Files).subtracting(localImage360Files)
        let newImageFiles = Set(remoteImageFiles).subtracting(localImageFiles)

        print("New video files: \(newVideoFiles)")
        print("New 360 image files: \(newImage360Files)")
        print("New AR image files: \(newImageFiles)")

        return !newVideoFiles.isEmpty || !newImage360Files.isEmpty || !newImageFiles.isEmpty
    }

    func downloadFiles(progress: @escaping (Float) -> Void) async {
        var totalFiles: Int = 0
        var downloadedFiles: Int = 0
        var newImagesDownloaded = false

        do {
            let videoResult = try await storage.reference(withPath: "Videos").listAll()
            totalFiles += videoResult.items.count
            let image360Result = try await storage.reference(withPath: "360View").listAll()
            totalFiles += image360Result.items.count
            let imageResult = try await storage.reference().child("AR Images").listAll()
            totalFiles += imageResult.items.count
        } catch {
            print("Error counting files: \(error)")
        }

        await downloadVideos(progress: { downloaded in
            downloadedFiles += 1
            progress(Float(downloadedFiles) / Float(totalFiles))
        })

        await downloadImages360(progress: { downloaded in
            downloadedFiles += 1
            progress(Float(downloadedFiles) / Float(totalFiles))
        })

        newImagesDownloaded = await downloadImages(progress: { downloaded in
            downloadedFiles += 1
            progress(Float(downloadedFiles) / Float(totalFiles))
        })

        if newImagesDownloaded {
            createARReferenceImages()
        }
    }

    private func downloadVideos(progress: @escaping (Int) -> Void) async {
        let videoRef = storage.reference(withPath: "Videos")
        do {
            let result = try await videoRef.listAll()
            for item in result.items {
                let localURL = self.videosDirectory.appendingPathComponent(item.name)
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try await downloadFileAsync(from: item, to: localURL)
                    progress(1)
                }
            }
        } catch {
            print("Error listing or downloading videos: \(error)")
        }
    }

    private func downloadImages360(progress: @escaping (Int) -> Void) async {
        let image360Ref = storage.reference(withPath: "360View")
        do {
            let result = try await image360Ref.listAll()
            for item in result.items {
                let localURL = self.images360Directory.appendingPathComponent(item.name)
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try await downloadFileAsync(from: item, to: localURL)
                    progress(1)
                }
            }
        } catch {
            print("Error listing or downloading images360: \(error)")
        }
    }

    private func downloadImages(progress: @escaping (Int) -> Void) async -> Bool {
        let imageRef = storage.reference().child("AR Images")
        var newImagesDownloaded = false
        do {
            let result = try await imageRef.listAll()
            for item in result.items {
                let localURL = self.imagesDirectory.appendingPathComponent(item.name)
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try await downloadFileAsync(from: item, to: localURL)
                    progress(1)
                    newImagesDownloaded = true
                }
            }
        } catch {
            print("Error listing or downloading images: \(error)")
        }
        return newImagesDownloaded
    }

    private func downloadFileAsync(from storageRef: StorageReference, to localURL: URL) async throws {
        let filename = localURL.lastPathComponent

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storageRef.write(toFile: localURL) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    print("Download complete for file: \(filename)")
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteMissingLocalFiles() async {
        await deleteMissingFiles(in: videosDirectory, storageRefPath: "Videos")
        await deleteMissingFiles(in: images360Directory, storageRefPath: "360View")
        await deleteMissingFiles(in: imagesDirectory, storageRefPath: "AR Images")
    }

    private func deleteMissingFiles(in localDirectory: URL, storageRefPath: String) async {
        let fileManager = FileManager.default
        do {
            let localFiles = try fileManager.contentsOfDirectory(at: localDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let storageRef = storage.reference().child(storageRefPath)
            do {
                let result = try await storageRef.listAll()
                let onlineFiles = result.items.map { $0.name }
                for localFileURL in localFiles {
                    let localFile = localFileURL.lastPathComponent
                    if !onlineFiles.contains(localFile) {
                        try fileManager.removeItem(at: localFileURL)
                    }
                }
            } catch {
                print("Error listing \(storageRefPath) files: \(error)")
            }
        } catch {
            print("Error reading local directory \(localDirectory.path): \(error)")
        }
    }

    func createARReferenceImages() {
        arReferenceImages.removeAll()
        let fileManager = FileManager.default
        do {
            let imageFiles = try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
            print("Found \(imageFiles.count) image files in directory.")  // Debug log
            for file in imageFiles {
                let imageURL = imagesDirectory.appendingPathComponent(file)
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    let components = file.split(separator: "-")
                    if components.count > 1, let widthString = components[1].split(separator: ".").first,
                       let physicalWidthCM = Double(widthString) {
                        let physicalWidth = CGFloat((physicalWidthCM) / 100.0)  // Convert cm to meters
                        guard let cgImage = image.cgImage else {
                            print("Error: Could not create CGImage from file \(file)")
                            continue
                        }
                        let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: physicalWidth)
                        arImage.name = file
                        arReferenceImages.append(arImage)
                        print("Created ARReferenceImage: \(file) with width: \(physicalWidth) meters")  // Debug log
                    } else {
                        print("Error: Could not parse physical width from file \(file)")
                    }
                } else {
                    print("Error: Could not create UIImage from file \(file)")
                }
            }
        } catch {
            print("Error reading files in directory \(imagesDirectory.path): \(error)")
        }
        loadLocalARReferenceImages() // Ensure local images are also added
        print("Total ARReferenceImages created: \(arReferenceImages.count)")  // Debug log
    }

    func getARReferenceImages() -> [ARReferenceImage] {
        return arReferenceImages
    }
}

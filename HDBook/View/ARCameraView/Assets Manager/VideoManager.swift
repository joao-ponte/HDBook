//
//  VideoManager.swift
//  HDBook
//
//  Created by hayesdavidson on 24/07/2024.
//

import AVKit
import RealityKit

class VideoManager {
    var videoPlayers: [UUID: AVPlayer] = [:]
    
    func createVideoScreen(width: Float, height: Float, url: URL, uuid: UUID) -> ModelEntity {
        let screenMesh = MeshResource.generatePlane(width: width, height: height)
        let videoItem = createVideoItem(with: url)
        let videoMaterial = createVideoMaterial(with: videoItem, uuid: uuid)
        let videoScreenModel = ModelEntity(mesh: screenMesh, materials: [videoMaterial])
        return videoScreenModel
    }

    private func createVideoItem(with url: URL) -> AVPlayerItem {
        let asset = AVURLAsset(url: url)
        return AVPlayerItem(asset: asset)
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
}

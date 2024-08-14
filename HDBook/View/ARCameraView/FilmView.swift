//
//  FilmView.swift
//  HDBook
//
//  Created by hayesdavidson on 14/08/2024.
//

import SwiftUI
import AVKit

struct FilmView: View {
    let filmURL: URL
    @EnvironmentObject var coordinator: ARViewCoordinator
    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            if let player = player {
                VideoPlayer(player: player)
                    .overlay(
                        Button(action: {
                            coordinator.exitFilmView()
                        }) {
                            Image(systemName: "arrow.backward.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 28))
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, geometry.safeAreaInsets.top + 40)
                        .padding(.leading, geometry.safeAreaInsets.leading)
                    )
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        player = AVPlayer(url: filmURL)
                    }
            }
        }
        .interfaceOrientations(.landscape)
    }
}

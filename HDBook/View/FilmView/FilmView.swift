//
//  FilmView.swift
//  HDBook
//
//  Created by hayesdavidson on 14/08/2024.
//

import SwiftUI
import AVKit
import InterfaceOrientation

struct FilmView: View {
    let filmURL: URL
    @EnvironmentObject var coordinator: ARViewCoordinator
    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Only show the close button if the screen is in portrait mode
                if !isLandscape(geometry: geometry) {
                    HStack {
                        Button(action: {
                            coordinator.exitFilmView()
                        }) {
                            Image("closeImageX") // Replace with your custom image name
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.leading)
                }
                
                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            DragGesture().onEnded { value in
                                if value.translation.height > 100 {
                                    coordinator.exitFilmView()
                                }
                            }
                        )
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
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black)
            .interfaceOrientations(.landscape)
        }
    }

    // Check if the screen is in landscape mode using the screen dimensions
    private func isLandscape(geometry: GeometryProxy) -> Bool {
        return geometry.size.width > geometry.size.height
    }
}

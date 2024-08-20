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
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) { // Use spacing to reduce the gap
                if verticalSizeClass != .compact {
                    HStack {
                        Button(action: {
                            coordinator.exitFilmView()
                        }) {
                            Image(systemName: "arrow.backward.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 28))
                        }
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
            .interfaceOrientations(.landscape)
        }
    }
}

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
            if let player = player {
                VideoPlayer(player: player)
                    .overlay(
                        verticalSizeClass == .compact ? nil :
                        HStack {
                            Spacer()
                            Button(action: {
                                coordinator.exitFilmView()
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.green)
                                    .font(.system(size: 28))
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        .padding(.trailing, geometry.safeAreaInsets.trailing + 20)
                    )
                    .edgesIgnoringSafeArea(.all)
                    .gesture(
                        DragGesture().onEnded { value in
                            if value.translation.width > 100 || value.translation.height > 100 {
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
        .interfaceOrientations(.landscape)
    }
}

//
//  SuperZoomView.swift
//  HDBook
//
//  Created by hayesdavidson on 02/08/2024.
//

import SwiftUI

struct SuperZoomView: View {
    let imageURL: URL
    @EnvironmentObject var coordinator: ARViewCoordinator
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0

    var body: some View {
        VStack {
            GeometryReader { geometry in
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(currentScale * finalScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    currentScale = value
                                }
                                .onEnded { value in
                                    finalScale *= value
                                    currentScale = 1.0
                                }
                        )
                } placeholder: {
                    ProgressView()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    HStack {
                        Button(action: {
                            coordinator.exitSuperZoomView()
                        }) {
                            Image(systemName: "arrow.backward.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 28))
                        }
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
            )
        }
    }
}

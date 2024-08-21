//
//  SuperZoomView.swift
//  HDBook
//
//  Created by hayesdavidson on 09/08/2024.
//

import SwiftUI

struct SuperZoomView: View {
    let imageURL: URL
    @EnvironmentObject var coordinator: ARViewCoordinator
    @State private var uiImage: UIImage? = nil
    @State private var zoomState: ZoomState = .min
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = uiImage {
                ImageZoomView(
                    proxy: geometry,
                    isInteractive: .constant(true),
                    zoomState: $zoomState,
                    maximumZoomScale: 4.0,
                    content: UIImageView(image: uiImage)
                )
                .overlay(
                    !isLandscape ? AnyView(
                        Button(action: {
                            coordinator.exitSuperZoomView()
                        }) {
                            Image(systemName: "arrow.backward.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 28))
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.leading, geometry.safeAreaInsets.leading)
                    ) : AnyView(EmptyView())
                )
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
            } else {
                ProgressView()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onRotate { newOrientation in
            currentOrientation = newOrientation
        }
        .interfaceOrientations(.landscape)
    }

    private var isLandscape: Bool {
        return currentOrientation.isLandscape
    }

    private func loadImage() {
        Task {
            do {
                let data = try Data(contentsOf: imageURL)
                self.uiImage = UIImage(data: data)
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
}

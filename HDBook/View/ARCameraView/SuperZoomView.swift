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

    var body: some View {
        VStack {
            ZoomableScrollView {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
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

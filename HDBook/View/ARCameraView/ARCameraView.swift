//
//  ARCameraView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import RealityKit
import ARKit

struct ARCameraView: View {
    @EnvironmentObject var coordinator: ARViewCoordinator
    let linkToPhotos = URL(string: "https://www.hayesdavidson.com/portfolio/360s")!

    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            TopBar(linkToPhotos: linkToPhotos)
        }
        .onAppear {
            Task {
                await coordinator.resumeARSession()
            }
        }
        .onDisappear {
            coordinator.pauseARSession()
            Task {
                await coordinator.removeAllAnchors()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct TopBar: View {
    let linkToPhotos: URL
    @EnvironmentObject var coordinator: ARViewCoordinator
    var body: some View {
        HStack {
            if coordinator.is360ViewActive {
                Button(action: {
                    coordinator.exit360View()
                }) {
                    Image(systemName: "arrow.backward.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 28))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            } else {
                ShareLink(item: linkToPhotos) {
                    Text("Image Library")
                }
                .padding(10)
                .font(Font.custom("CaslonDoric-Medium", size: 12))
                .foregroundStyle(Color.green)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green, lineWidth: 2)
                )
                Spacer()
                NavigationLink("Tutorial") {
                    ModifiedTutorialView(viewModel: TutorialCardsViewModel())
                        .onAppear {
                            coordinator.pauseARSession()
                            Task {
                                await coordinator.removeAllAnchors()
                            }
                        }
                }
                .padding()
                .font(Font.custom("CaslonDoric-Medium", size: 16))
                .foregroundStyle(Color.green)
            }
        }
        .padding()
    }
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var coordinator: ARViewCoordinator

    typealias UIViewType = ARView

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        Task {
            await context.coordinator.configureARView(arView)
        }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> ARViewCoordinator {
        return coordinator
    }
}

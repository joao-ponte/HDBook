//
//  ARCameraView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import RealityKit
import ARKit
import InterfaceOrientation

struct ARCameraView: View {
    @EnvironmentObject var coordinator: ARViewCoordinator

    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            TopBar()

            // Custom alert overlay
            if coordinator.showAlert {
                NoInternetAlertView {
                    coordinator.dismissAlertAndResetARSession()
                }
                .transition(.opacity)
                .zIndex(1)
            }

            // Custom tap-to-dismiss overlay
            if coordinator.show360ViewAlert {
                GeometryReader { geometry in
                    Color.black.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            coordinator.dismiss360ViewAlert()
                        }
                        .overlay(
                            VStack(/*spacing: geometry.size.height * 0.02*/) { // Adjusts spacing based on screen height
                                Text("You have entered a 360-degree view. Use motion to explore.")
                                    .font(.custom(Fonts.CaslonDoric.regular, size: geometry.size.width * 0.06)) // Relative font size
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                VStack(/*spacing: geometry.size.height * 0.01*/) {
                                    Image("orbitIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4) // Relative image size

                                    Text("Move your device to experience the 360.")
                                        .font(.custom(Fonts.CaslonDoric.regular, size: geometry.size.width * 0.06)) // Relative font size
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .cornerRadius(10)
                            }
                            .padding()
                            .background(AppColors.Active.grey.opacity(0.6))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        )
                        .zIndex(2)
                        .transition(.opacity)
                }
            }
        }
        .interfaceOrientations(.portrait)
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
        .fullScreenCover(isPresented: $coordinator.isSuperZoomPresented) {
            if let superZoomURL = coordinator.superZoomURL {
                SuperZoomView(imageURL: superZoomURL)
                    .environmentObject(coordinator)
            }
        }
        .fullScreenCover(isPresented: $coordinator.isFilmPresented) {
            if let filmURL = coordinator.filmURL {
                FilmView(filmURL: filmURL)
                    .environmentObject(coordinator)
            }
        }
    }
}


struct TopBar: View {
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

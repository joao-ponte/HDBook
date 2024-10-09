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
    @State private var showTutorial = false  // State for manual navigation

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
                    Color.black.opacity(0.45)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack {
                                Text("360-degree view enabled")
                                    .font(.custom("CaslonDoric-Medium", size: geometry.size.width * 0.12)
                                        .weight(.medium))
                                    .foregroundColor(.white)
                                    .lineSpacing(8)
                                    .padding(.horizontal)
                                    .padding(.bottom, geometry.size.height * (49.5 / 812))
                                
                                VStack {
                                    Image("Alert360View")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * (280 / 375), height: geometry.size.height * (280 / 812))
                                    
                                    Text("Move your device to experience the 360.")
                                        .font(.custom("CaslonDoric-Medium", size: geometry.size.width * 0.05)
                                            .weight(.medium))
                                        .foregroundColor(.white)
                                        .lineSpacing(8)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                        .padding(.horizontal, geometry.size.width * (50 / 375))
                                        .padding(.top, geometry.size.height * (49.5 / 812))
                                }
                            }
                        )
                        .zIndex(2)
                        .onTapGesture {
                            coordinator.dismiss360ViewAlert()
                        }
                }
            }
            
            if coordinator.activeAnchors.isEmpty && !coordinator.is360ViewActive && !coordinator.isTrackingAsset {
                GeometryReader { geometry in
                    Image("rectangleFrame")
                        .resizable()
                        .scaledToFit()
                        .zIndex(3)
                        .padding(.horizontal, geometry.size.width * (28 / 375)) // Proportional horizontal padding
                        .padding(.vertical, geometry.size.height * (246 / 812)) // Proportional vertical padding
                }
            }
            
            // Tutorial button at the bottom
            if !coordinator.is360ViewActive {
                VStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                showTutorial = true // Trigger navigation
                                coordinator.pauseARSession() // Pause the AR Session when navigating to the tutorial
                            }
                        }) {
                            Text("Tutorial")
                                .font(Font.custom("Caslon Doric", size: 17).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(50)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        // Manual transition for Tutorial View
        .overlay(
            ZStack {
                if showTutorial {
                    ModifiedTutorialView(viewModel: TutorialCardsViewModel())
                        .transition(.move(edge: .leading)) // Left-to-right transition
                        .onAppear {
                            // AR session is already paused when transitioning to this view
                        }
                        .onDisappear {
                            // Resume AR session when leaving the tutorial view
                            Task {
                                await coordinator.resumeARSession()
                            }
                        }
                }
            }
        )
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
    @EnvironmentObject var coordinator: ARViewCoordinator
    
    var body: some View {
        HStack {
            if coordinator.is360ViewActive {
                Button(action: {
                    if coordinator.videoEntity != nil {
                        coordinator.exitVideo360View()
                    } else {
                        coordinator.exit360View()
                    }
                }) {
                    Image("closeImageX")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
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

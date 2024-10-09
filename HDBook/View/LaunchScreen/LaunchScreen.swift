//
//  LaunchScreen.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import Reachability
import InterfaceOrientation
import SceneKit

struct LaunchScreen: View {
    @ObservedObject var viewModel: TutorialCardsViewModel
    @State private var isFirstLaunch = true
    @State private var hasNewAssets = false
    @State private var showDownloadPrompt = false
    @State private var isDownloading = false
    @State private var downloadProgress: Float = 0.0
    @State private var isOffline = false
    @State private var showLaunchButton = false
    @EnvironmentObject var coordinator: ARViewCoordinator
    private let reachability = try! Reachability()
    
    // Add a boolean to control whether to check for assets
    @State private var shouldCheckForAssets: Bool = true
    
    @State private var scene: SCNScene? = {
        guard let url = Bundle.main.url(forResource: "HDLogo_ARM", withExtension: "usdz", subdirectory: "3DModels.scnassets"),
              let scene = try? SCNScene(url: url, options: nil) else {
            fatalError("Unable to load model named HDLogo_ARM.usdz from 3DModels.scnassets")
        }
        return scene
    }()
    
    @State private var startColor: Color = Color(red: 0.9, green: 0.1, blue: 0.1)
    @State private var endColor: Color = Color(red: 0.3, green: 0, blue: 0)
    
    init(viewModel: TutorialCardsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [startColor, endColor]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0))
                    
                    VStack(spacing: 0) {
                        // 3D Model View
                        CustomModelView(scene: $scene, onRotate: updateGradientColors)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                            .cornerRadius(20)
                        
                        // Logic for displaying different UI elements
                        if isDownloading {
                            ProgressView("Downloading...", value: downloadProgress, total: 1.0)
                                .padding()
                                .progressViewStyle(WhiteLinearProgressViewStyle())
                        } else if showDownloadPrompt {
                            downloadPromptView
                        } else if showLaunchButton {
                            launchButton
                        }
                    }
                }
                .onAppear {
                    if shouldCheckForAssets {
                        checkInternetConnection()
                    } else {
                        showLaunchButton = true
                    }
                    isFirstLaunch = viewModel.isFirstLaunch
                    viewModel.isFirstLaunch = false
                }
            }
        }
        .interfaceOrientations(.portrait)
        .toolbar(.hidden, for: .navigationBar)
        .navigationViewStyle(.stack)
        .navigationBarHidden(true)
    }
    
    private func updateGradientColors(rotationX: CGFloat, rotationY: CGFloat) {
        let redStart = abs(sin(Double(rotationX))) * 0.5 + 0.5
        let redEnd = abs(cos(Double(rotationY))) * 0.3 + 0.3
        let blackTone = abs(sin(Double(rotationX * rotationY))) * 0.5
        
        startColor = Color(red: redStart, green: 0, blue: 0)
        endColor = Color(red: redEnd, green: 0, blue: 0).opacity(1 - blackTone)
    }
    
    private var downloadPromptView: some View {
        VStack {
            Text("""
                 There are updated image assets available for use.
                 Would you like to download?
                """)
            .font(.custom("CaslonDoric-Medium", size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding()
            
            HStack {
                Spacer()
                Button(action: {
                    showLaunchButton = true
                    showDownloadPrompt = false
                }) {
                    Text("No")
                        .padding([.top, .bottom], 14)
                        .padding([.trailing, .leading], 34)
                        .font(.custom("CaslonDoric-Medium", size: 13))
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                }
                Spacer()
                Button(action: startDownload) {
                    Text("Yes")
                        .padding([.top, .bottom], 14)
                        .padding([.trailing, .leading], 34)
                        .font(.custom("CaslonDoric-Medium", size: 13))
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                }
                Spacer()
            }
        }
        .padding(.bottom, 56)
    }
    
    private func disposeSCNView() {
            scene = nil // This will release the SCNScene and any associated resources
        }
    
    private var launchButton: some View {
        VStack {
            Spacer() // This will push the button towards the bottom
            
            Button(action: {
                disposeSCNView() // Dispose of the SCNView and associated resources
            }) {
                NavigationLink(destination: isFirstLaunch ? AnyView(TutorialView(viewModel: TutorialCardsViewModel())) : AnyView(ARCameraView().environmentObject(coordinator))) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("Launch")
                            .font(
                                Font.custom("Caslon Doric", size: 24)
                                    .weight(.medium) // Updated font and weight from Figma
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    .background(
                        Color.white.opacity(0.25) // Set the background opacity
                    )
                    .cornerRadius(50) // Rounded corners based on Figma design
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.bottom, 32)
    }

    
    private func checkInternetConnection() {
        if shouldCheckForAssets {
            ConnectivityManager.isInternetAccessible { isConnected in
                DispatchQueue.main.async {
                    if isConnected {
                        Task {
                            do {
                                hasNewAssets = try await FirebaseStorageService.shared.hasNewAssets()
                                if hasNewAssets {
                                    showDownloadPrompt = true
                                } else {
                                    showLaunchButton = true
                                }
                            } catch {
                                showLaunchButton = true
                            }
                        }
                    } else {
                        showLaunchButton = true
                    }
                }
            }
        }
    }
    
    private func startDownload() {
        if shouldCheckForAssets {  // Only run this if asset checking is enabled
            isDownloading = true
            showDownloadPrompt = false
            
            Task {
                do {
                    await FirebaseStorageService.shared.downloadFiles(progress: { progress in
                        DispatchQueue.main.async {
                            downloadProgress = progress
                        }
                    })
                    DispatchQueue.main.async {
                        convertLocalImages()
                        showLaunchButton = true
                        isDownloading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        // Handle error
                        showLaunchButton = true
                        isDownloading = false
                    }
                }
            }
        }
    }
    
    private func convertLocalImages() {
        if shouldCheckForAssets {  // Only run this if asset checking is enabled
            Task {
                FirebaseStorageService.shared.createARReferenceImages()
                DispatchQueue.main.async {
                    showLaunchButton = true
                }
            }
        }
    }
}

struct WhiteLinearProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .frame(height: 10)
                    .foregroundColor(.gray.opacity(0.3))
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * UIScreen.main.bounds.width, height: 10)
                    .foregroundColor(.white)
            }
            if let label = configuration.label {
                label
                    .foregroundColor(.white)
            }
        }
    }
}

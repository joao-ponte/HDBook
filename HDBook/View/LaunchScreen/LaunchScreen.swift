//
//  LaunchScreen.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import Reachability

struct LaunchScreen: View {
    @ObservedObject var viewModel: TutorialCardsViewModel
    @State private var isFirstLaunch = true
    @State private var hasNewAssets = false
    @State private var showDownloadPrompt = false
    @State private var isDownloading = false
    @State private var downloadProgress: Float = 0.0
    @State private var isOffline = false
    @State private var showLaunchButton = false
    @State private var isLoading = false
    @EnvironmentObject var coordinator: ARViewCoordinator
    private let reachability = try! Reachability()
    
    init(viewModel: TutorialCardsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            GeometryReader {geometry in
                ZStack {
                    Color.red
                    VStack {
                        Spacer()
                        Spacer()
                        
                        Image("Logotype")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, geometry.size.width * 0.09)
                        
                        Text("HD Book")
                            .font(.custom("CaslonDoric-Medium", size: geometry.size.width * 0.06))
                            .foregroundColor(.white)
                            .padding(.top, geometry.size.height * 0.009)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    VStack {
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                                .padding([.bottom], 70)
                        } else if isDownloading {
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
                .ignoresSafeArea()
                .dynamicTypeSize(.xSmall ... .accessibility4)
                .onAppear {
                    checkInternetConnection()
                    isFirstLaunch = viewModel.isFirstLaunch
                    viewModel.isFirstLaunch = false
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationViewStyle(.stack)
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
                Button(action: convertLocalImages) {
                    Text("No ")
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
    
    private var launchButton: some View {
        NavigationLink(destination: isFirstLaunch ? AnyView(TutorialView(viewModel: TutorialCardsViewModel())) : AnyView(ARCameraView().environmentObject(coordinator))) {
            Text("Launch")
                .padding()
                .font(.custom("CaslonDoric-Medium", size: 16))
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white, lineWidth: 2)
                )
        }
        .padding(.bottom, 56)
    }
    
    private func checkInternetConnection() {
        Task {
            isLoading = true
            do {
                try await reachability.startNotifier()
                isOffline = reachability.connection == .unavailable
                if isOffline {
                    convertLocalImages()
                } else {
                    hasNewAssets = try await FirebaseStorageService.shared.hasNewAssets()
                    DispatchQueue.main.async {
                        isLoading = false
                        if hasNewAssets {
                            showDownloadPrompt = true
                        } else {
                            convertLocalImages()
                        }
                    }
                }
            } catch {
                isOffline = true
                convertLocalImages()
            }
        }
    }
    
    private func startDownload() {
        isDownloading = true
        Task {
            do {
                await FirebaseStorageService.shared.downloadFiles(progress: { progress in
                    DispatchQueue.main.async {
                        downloadProgress = progress
                    }
                })
                DispatchQueue.main.async {
                    convertLocalImages()
                }
            }        }
    }
    
    private func convertLocalImages() {
        Task {
            FirebaseStorageService.shared.createARReferenceImages()
            DispatchQueue.main.async {
                isLoading = false
                isDownloading = false
                showDownloadPrompt = false
                showLaunchButton = true
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

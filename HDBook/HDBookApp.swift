//
//  HDBookApp.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import InterfaceOrientation

@main
struct HDBookApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var arViewCoordinator = ARViewCoordinator(firebaseStorageService: FirebaseStorageService.shared)

    var body: some Scene {
        WindowGroup {
            LaunchScreen(viewModel: TutorialCardsViewModel())
                .environmentObject(arViewCoordinator)
                .onAppear {
                    Task {
                        await arViewCoordinator.loadARReferenceImages()
                    }
                }
        }
    }
}


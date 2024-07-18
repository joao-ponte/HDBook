//
//  HDBookApp.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI

@main
struct HDBookApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LaunchScreen(viewModel: TutorialCardsViewModel())
                .environmentObject(ARViewCoordinator(firebaseStorageService: FirebaseStorageService.shared))
        }
    }
}

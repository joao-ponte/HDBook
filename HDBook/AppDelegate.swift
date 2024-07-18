//
//  AppDelegate.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import UIKit
import SwiftUI
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        guard FirebaseApp.app() != nil else {
            return false
        }
        deleteMissingFiles()

        let coordinator = ARViewCoordinator(firebaseStorageService: FirebaseStorageService.shared)
        let contentView = LaunchScreen(viewModel: TutorialCardsViewModel())
            .environmentObject(coordinator)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()

        return true
    }

    func deleteMissingFiles() {
        Task {
            do {
                await FirebaseStorageService.shared.deleteMissingLocalFiles()
            } catch {
                print("Error during deletion of missing local files: \(error)")
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
}

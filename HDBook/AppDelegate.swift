//
//  AppDelegate.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import UIKit
import SwiftUI
import FirebaseCore
import InterfaceOrientation

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        guard FirebaseApp.app() != nil else {
            return false
        }

        Task {
            await FirebaseStorageService.shared.deleteMissingLocalFiles()
        }

        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            InterfaceOrientationCoordinator.shared.supportedOrientations
        }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
}

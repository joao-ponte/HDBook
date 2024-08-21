//
//  NotificationManager.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import UIKit
import UserNotifications

class NotificationManager {
    static func showOfflineNotification() {
        let content = UNMutableNotificationContent()
        content.title = "No Internet Connection"
        content.body = "Please check your internet connection and try again."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "OfflineNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

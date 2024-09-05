//
//  ConnectivityManager.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import Reachability
import Foundation

class ConnectivityManager {
    
    static func isConnectedToInternet() -> Bool {
        let reachability = try? Reachability()
        return reachability?.connection != .unavailable
    }
    
    static func isInternetAccessible(completion: @escaping (Bool) -> Void) {
        guard isConnectedToInternet() else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: URL(string: "https://www.google.com")!)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

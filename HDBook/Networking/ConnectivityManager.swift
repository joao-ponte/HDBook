//
//  ConnectivityManager.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import Reachability

class ConnectivityManager {
    static func isConnectedToInternet() -> Bool {
        let reachability = try? Reachability()
        return reachability?.connection != .unavailable
    }
}

//
//  View+Extensions.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import SwiftUI

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.onAppear {
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                action(UIDevice.current.orientation)
            }
        }
    }
}

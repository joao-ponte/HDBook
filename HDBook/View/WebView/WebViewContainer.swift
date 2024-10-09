//
//  WebViewManager.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Environment(\.presentationMode) var presentationMode  // To handle the dismissal
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // Add this view for your back arrow
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        // Handle webview navigation or other functionality if needed
    }
}

//
//  WebViewManager.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import SafariServices
import UIKit

class WebViewManager {
    static func presentWebView(url: URL, in viewController: UIViewController) {
        let safariVC = SFSafariViewController(url: url)
        viewController.present(safariVC, animated: true, completion: nil)
    }
}

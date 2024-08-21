//
//  ImageZoomView.swift
//  HDBook
//
//  Created by hayesdavidson on 09/08/2024.
//

import SwiftUI

enum ZoomState: Comparable {
    case min, partial
    case max(center: CGPoint?)
    
    static func < (lhs: ZoomState, rhs: ZoomState) -> Bool {
        switch lhs {
        case .min:
            return rhs == .min
        case .partial:
            return rhs == .partial
        case let .max(center):
            return rhs == .max(center: center)
        }
    }
}

struct ImageZoomView: UIViewRepresentable {
    let proxy: GeometryProxy
    @Binding var isInteractive: Bool
    @Binding var zoomState: ZoomState
    let maximumZoomScale: CGFloat
    
    let content: UIView
    
    var size: CGSize {
        proxy.size + CGSize(width: proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing, height: proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
    }
    
    var intrinsicContentSize: CGSize {
        content.intrinsicContentSize
    }
    
    var minimumZoomScale: CGFloat {
        intrinsicContentSize.aspectRatio > size.aspectRatio ? size.width / intrinsicContentSize.width : size.height / intrinsicContentSize.height
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let uiScrollView = UIScrollView()
        uiScrollView.delegate = context.coordinator
        uiScrollView.showsVerticalScrollIndicator = false
        uiScrollView.showsHorizontalScrollIndicator = false
        uiScrollView.clipsToBounds = false

        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTapGesture(gestureRecognizer:)))
        gesture.numberOfTapsRequired = 2
        content.addGestureRecognizer(gesture)
        content.isUserInteractionEnabled = isInteractive
        
        uiScrollView.isUserInteractionEnabled = isInteractive
        uiScrollView.addSubview(content)
        return uiScrollView
    }
    
    func updateUIView(_ uiScrollView: UIScrollView, context: Context) {
        uiScrollView.isUserInteractionEnabled = isInteractive
        uiScrollView.subviews.first?.isUserInteractionEnabled = isInteractive
        
        if uiScrollView.minimumZoomScale != minimumZoomScale {
            uiScrollView.minimumZoomScale = minimumZoomScale
            uiScrollView.maximumZoomScale = maximumZoomScale

            switch zoomState {
            case .min:
                uiScrollView.setZoomScale(minimumZoomScale, animated: false)
            case .max:
                uiScrollView.setZoomScale(maximumZoomScale, animated: false)
            default:
                break
            }

            let contentOffset = uiScrollView.contentOffset - CGPoint(cgSize: (size - uiScrollView.visibleSize) / 2)
            updateInset(uiScrollView)
            
            uiScrollView.contentOffset = contentOffset
        } else {
            switch zoomState {
            case .min:
                if uiScrollView.zoomScale != uiScrollView.minimumZoomScale {
                    uiScrollView.setZoomScale(minimumZoomScale, animated: !UIAccessibility.isReduceMotionEnabled)
                }
            case let .max(center):
                if uiScrollView.zoomScale != uiScrollView.maximumZoomScale {
                    // offset to center here
                    if let center = center {
                        let rect = CGRect(x: center.x, y: center.y, width: 1, height: 1)
                        uiScrollView.zoom(to: rect, animated: !UIAccessibility.isReduceMotionEnabled)
                    }
                }
            default:
                break
            }
        }
    }
    
    func updateInset(_ uiScrollView: UIScrollView) {
        let offset = (size - uiScrollView.contentSize) / 2.0
        uiScrollView.contentInset = UIEdgeInsets(top: max(offset.height, 0), left: max(offset.width, 0), bottom: 0, right: 0)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ImageZoomView
        
        init(_ parent: ImageZoomView) {
            self.parent = parent
        }
        
        @objc func handleDoubleTapGesture(gestureRecognizer: UITapGestureRecognizer) {
            guard let scrollView = gestureRecognizer.view?.superview as? UIScrollView else { return }

            let customZoomScale: CGFloat = (scrollView.minimumZoomScale + scrollView.maximumZoomScale) / 5

            if scrollView.zoomScale < customZoomScale {
                // Zoom in to the custom zoom scale
                let location = gestureRecognizer.location(in: gestureRecognizer.view)
                let zoomRect = zoomRectForScale(scale: customZoomScale, center: location, scrollView: scrollView)
                scrollView.zoom(to: zoomRect, animated: true)
                parent.zoomState = .partial
            } else {
                // Zoom out to the minimum zoom scale
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                parent.zoomState = .min
            }
        }

        func zoomRectForScale(scale: CGFloat, center: CGPoint, scrollView: UIScrollView) -> CGRect {
            let size = CGSize(width: scrollView.frame.size.width / scale, height: scrollView.frame.size.height / scale)
            let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
            return CGRect(origin: origin, size: size)
        }

        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            switch scrollView.zoomScale {
            case scrollView.minimumZoomScale:
                parent.zoomState = .min
            case scrollView.maximumZoomScale:
                parent.zoomState = .max(center: nil)
            default:
                parent.zoomState = .partial
            }
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.updateInset(scrollView)
        }
    }
}

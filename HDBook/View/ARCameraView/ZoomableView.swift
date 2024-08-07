//
//  ZoomableScrollView.swift
//  HDBook
//
//  Created by hayesdavidson on 02/08/2024.
//

import SwiftUI

struct ZoomableView<Content: View>: View {
    let content: Content
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .overlay(content: {
                    GeometryReader { proxy in
                        let rect = proxy.frame(in: .named("ZoomableView"))
                        Color.clear
                            .onChange(of: isInteracting) { newValue in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if rect.minX > 0 {
                                        offset.width = (offset.width - rect.minX)
                                        haptics(.medium)
                                    }
                                    if rect.minY > 0 {
                                        offset.height = (offset.height - rect.minY)
                                        haptics(.medium)
                                    }
                                    
                                    if rect.maxX < geometry.size.width {
                                        offset.width = (rect.minX - offset.width)
                                        haptics(.medium)
                                    }
                                    if rect.maxY < geometry.size.height {
                                        offset.height = (rect.minY - offset.height)
                                        haptics(.medium)
                                    }
                                    
                                }
                                if !newValue {
                                    lastStoredOffset = offset
                                }
                            }
                    }
                })
        }
        .scaleEffect(scale)
        .offset(offset)
        .coordinateSpace(name: "ZoomableView")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let translation = value.translation
                    offset = CGSize(width: translation.width + lastStoredOffset.width, height: translation.height + lastStoredOffset.height)
                })

        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let updatedScale = value + lastScale
                    scale = (updatedScale < 1 ? 1 : updatedScale)
                }).onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)){
                        if scale < 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                })
            
        )
    }
    func haptics(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

//
//  ZoomableScrollView.swift
//  HDBook
//
//  Created by hayesdavidson on 02/08/2024.
//

import SwiftUI

struct ZoomableView<Content: View>: View {
    let content: Content
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var initialScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let deltaScale = value / initialScale
                            self.scale = max(1.0, self.scale * deltaScale)
                            self.initialScale = value
                        }
                        .onEnded { _ in
                            self.initialScale = 1.0
                            self.adjustOffset(geometry: geometry)
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.offset = CGSize(width: value.translation.width + self.lastOffset.width,
                                                 height: value.translation.height + self.lastOffset.height)
                        }
                        .onEnded { _ in
                            self.lastOffset = self.offset
                            self.adjustOffset(geometry: geometry)
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            resetZoom()
                        } else {
                            zoomIn(geometry: geometry)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
    }

    private func zoomIn(geometry: GeometryProxy) {
        scale = 2.0

        // Calculate the offset to zoom into the double-tapped area
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let newOffsetX = (center.x - geometry.size.width / 2) * scale
        let newOffsetY = (center.y - geometry.size.height / 2) * scale

        offset = CGSize(width: -newOffsetX, height: -newOffsetY)
        lastOffset = offset
    }

    private func adjustOffset(geometry: GeometryProxy) {
        let maxOffsetX = (geometry.size.width * scale - geometry.size.width) / 2
        let maxOffsetY = (geometry.size.height * scale - geometry.size.height) / 2

        let minOffsetX = -maxOffsetX
        let minOffsetY = -maxOffsetY

        if offset.width > maxOffsetX {
            offset.width = maxOffsetX
        } else if offset.width < minOffsetX {
            offset.width = minOffsetX
        }

        if offset.height > maxOffsetY {
            offset.height = maxOffsetY
        } else if offset.height < minOffsetY {
            offset.height = minOffsetY
        }

        lastOffset = offset
    }
}

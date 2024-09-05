//
//  ARModelView.swift
//  HDBook
//
//  Created by hayesdavidson on 28/08/2024.
//

import SwiftUI
import SceneKit

struct CustomModelView: UIViewRepresentable {
    
    @Binding var scene: SCNScene?
    var onRotate: (CGFloat, CGFloat) -> Void
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        
        // Enable camera control
        view.allowsCameraControl = false
        
        // Automatically enable lighting
        view.autoenablesDefaultLighting = true
        
        // Improve rendering quality
        view.antialiasingMode = .multisampling2X
        
        // Set the background color to clear
        view.backgroundColor = .clear
        
        // Assign the scene to the SCNView
        view.scene = scene
        
        // Adjust the root node's scale and position
        if let rootNode = view.scene?.rootNode {
            // Scale down the model to a visible size
            rootNode.scale = SCNVector3(0.9, 0.9, 0.9) // Adjust the scale values as needed
            
            // Center the model in front of the camera
            rootNode.position = SCNVector3(1, 0, 0)
            
            // Adjust camera position if needed
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(0, 0, 0) // Adjust the distance as needed
            rootNode.addChildNode(cameraNode)
        }
        
        // Add a directional light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(0, 0, 0)
        view.scene?.rootNode.addChildNode(lightNode)
        
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // No need to update anything in the scene for now
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomModelView
        var lastRotationX: Float = 0
        var lastRotationY: Float = 0
        
        init(_ parent: CustomModelView) {
            self.parent = parent
        }
        
        @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
            guard let view = sender.view as? SCNView else { return }
            let translation = sender.translation(in: view)
            
            // Adjust sensitivity by scaling down the translation values
            let sensitivity: Float = 0.5 // Adjust this value to control sensitivity
            let rotationX = Float(translation.y) * sensitivity * .pi / 180.0
            let rotationY = Float(translation.x) * sensitivity * .pi / 180.0
            
            if let entity = view.scene?.rootNode {
                // Calculate the new rotation values
                let newRotationX = entity.eulerAngles.x + (rotationX - lastRotationX)
                let newRotationY = entity.eulerAngles.y + (rotationY - lastRotationY)
                
                // Clamp the rotation to a maximum of 90 degrees (-90 to +90)
                entity.eulerAngles.x = max(min(newRotationX, .pi / 2), -.pi / 2)
                entity.eulerAngles.y = max(min(newRotationY, .pi / 2), -.pi / 2)
                
                lastRotationX = rotationX
                lastRotationY = rotationY
                
                // Notify parent view about the rotation
                parent.onRotate(CGFloat(entity.eulerAngles.x), CGFloat(entity.eulerAngles.y))
            }
            
            if sender.state == .ended {
                lastRotationX = 0
                lastRotationY = 0
            }
        }
    }
}

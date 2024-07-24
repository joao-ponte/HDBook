//
//  CTPanoramaCompass.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import UIKit
import SceneKit
import CoreMotion

@objc public protocol CTPanoramaCompass {
    func updateUI(rotationAngle: CGFloat, fieldOfViewAngle: CGFloat)
}

@objc public enum CTPanoramaControlMethod: Int {
    case motion
    case touch
    case both
}

@objc public enum CTPanoramaType: Int {
    case cylindrical
    case spherical
}

@objc public class CTPanoramaView: UIView, UIGestureRecognizerDelegate {
    
    @objc public var compass: CTPanoramaCompass?
    @objc public var movementHandler: ((_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat) -> Void)?

    @objc public var panSpeed = CGPoint(x: 0.4, y: 0.4)
    @objc public var startAngle: Float = 0

    @objc public var angleOffset: Float = 0 {
        didSet {
            geometryNode?.rotation = SCNQuaternion(0, 1, 0, angleOffset)
        }
    }

    @objc public var minFoV: CGFloat = 40
    @objc public var maxFoV: CGFloat = 100

    @objc public var image: UIImage? {
        didSet {
            panoramaType = panoramaTypeForCurrentImage
        }
    }

    @objc public var overlayView: UIView? {
        didSet {
            replace(overlayView: oldValue, with: overlayView)
        }
    }

    @objc public var panoramaType: CTPanoramaType = .cylindrical {
        didSet {
            createGeometryNode()
            resetCameraAngles()
        }
    }

    @objc public var controlMethod: CTPanoramaControlMethod = .touch {
        didSet {
            switchControlMethod(to: controlMethod)
            resetCameraAngles()
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            sceneView.backgroundColor = backgroundColor
        }
    }
    
    private let MaxPanGestureRotation: Float = GLKMathDegreesToRadians(360)
    private let radius: CGFloat = 10
    private let sceneView = SCNView()
    private let scene = SCNScene()
    private let motionManager = CMMotionManager()
    private var geometryNode: SCNNode?
    private var prevLocation = CGPoint.zero
    private var prevRotation = CGFloat.zero
    private var prevBounds = CGRect.zero

    private var motionPaused = false

    private lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        let camera = SCNCamera()
        node.camera = camera
        return node
    }()

    private lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    private lazy var fovHeight: CGFloat = {
        return tan(self.yFov/2 * .pi / 180.0) * 2 * self.radius
    }()
    
    private var startScale: CGFloat = 0.0

    private var xFov: CGFloat {
        return yFov * self.bounds.width / self.bounds.height
    }

    private var yFov: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                return cameraNode.camera?.fieldOfView ?? 0
            } else {
                return CGFloat(cameraNode.camera?.yFov ?? 0)
            }
        }
        set {
            if #available(iOS 11.0, *) {
                cameraNode.camera?.fieldOfView = newValue
            } else {
                cameraNode.camera?.yFov = Double(newValue)
            }
        }
    }

    private var panoramaTypeForCurrentImage: CTPanoramaType {
        if let image = image {
            if image.size.width / image.size.height == 2 {
                return .spherical
            }
        }
        return .cylindrical
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public convenience init(frame: CGRect, image: UIImage) {
        self.init(frame: frame)
        ({ self.image = image })()
    }

    deinit {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    private func commonInit() {
        add(view: sceneView)

        scene.rootNode.addChildNode(cameraNode)

        sceneView.scene = scene
        sceneView.backgroundColor = self.backgroundColor

        switchControlMethod(to: controlMethod)
     }

    public func resetCameraAngles() {
        yFov = maxFoV
        cameraNode.eulerAngles = SCNVector3Make(0, startAngle, 0)
    }

    private func createGeometryNode() {
        guard let image = image else { return }

        geometryNode?.removeFromParentNode()

        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front

        if panoramaType == .spherical {
            let sphere = SCNSphere(radius: radius)
            sphere.segmentCount = 300
            sphere.firstMaterial = material

            let sphereNode = SCNNode()
            sphereNode.geometry = sphere
            geometryNode = sphereNode
        } else {
            let tube = SCNTube(innerRadius: radius, outerRadius: radius, height: fovHeight)
            tube.heightSegmentCount = 50
            tube.radialSegmentCount = 300
            tube.firstMaterial = material

            let tubeNode = SCNNode()
            tubeNode.geometry = tube
            geometryNode = tubeNode
        }
        geometryNode?.rotation = SCNQuaternion(0, 1, 0, angleOffset)
        scene.rootNode.addChildNode(geometryNode!)
    }

    private func replace(overlayView: UIView?, with newOverlayView: UIView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else { return }
        add(view: newOverlayView)
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.015

        motionPaused = false
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: opQueue, withHandler: { [weak self] (motionData, error) in
            guard let panoramaView = self else { return }
            guard !panoramaView.motionPaused else { return }

            guard let motionData = motionData else {
                panoramaView.motionManager.stopDeviceMotionUpdates()
                return
            }

            DispatchQueue.main.async {
                if panoramaView.panoramaType == .cylindrical {
                    let rotationMatrix = motionData.attitude.rotationMatrix
                    var userHeading = .pi - atan2(rotationMatrix.m32, rotationMatrix.m31)
                    userHeading += .pi / 2

                    let startAngle = panoramaView.startAngle

                    // Prevent vertical movement in a cylindrical panorama
                    panoramaView.cameraNode.eulerAngles = SCNVector3Make(0, startAngle + Float(-userHeading), 0)
                } else {
                    let orientation = motionData.orientation()
                    panoramaView.cameraNode.orientation = orientation
                }
            }
        })
    }

    private func switchControlMethod(to method: CTPanoramaControlMethod) {
        sceneView.gestureRecognizers?.removeAll()

        if method == .touch {
            let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
            sceneView.addGestureRecognizer(panGestureRec)

            let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRec:)))
            sceneView.addGestureRecognizer(pinchRec)

            if motionManager.isDeviceMotionActive {
                motionManager.stopDeviceMotionUpdates()
            }
        } else {
            startMotionUpdates()
        }
    }

    // MARK: Gesture handling

    @objc private func handlePan(panRec: UIPanGestureRecognizer) {
        if panRec.state == .began {
            prevLocation = CGPoint.zero
        } else if panRec.state == .changed {
            var modifiedPanSpeed = panSpeed

            if panoramaType == .cylindrical {
                modifiedPanSpeed.y = 0 // Prevent vertical movement in a cylindrical panorama
            }

            let location = panRec.translation(in: sceneView)
            let translationDelta = CGPoint(x: (location.x - prevLocation.x) * modifiedPanSpeed.x, y: (location.y - prevLocation.y) * modifiedPanSpeed.y)

            // Use the pan translation along the x axis to adjust the camera's rotation about the y axis (side to side navigation).
            let yScalar = Float(translationDelta.x / self.bounds.size.width)
            let yRadians = yScalar * MaxPanGestureRotation

            // Use the pan translation along the y axis to adjust the camera's rotation about the x axis (up and down navigation).
            let xScalar = Float(translationDelta.y / self.bounds.size.height)
            let xRadians = xScalar * MaxPanGestureRotation

            // Represent the orientation as a GLKQuaternion
            var glQuaternion = GLKQuaternionMake(cameraNode.orientation.x, cameraNode.orientation.y, cameraNode.orientation.z, cameraNode.orientation.w)

            // Perform up and down rotations around *CAMERA* X axis (note the order of multiplication)
            let xMultiplier = GLKQuaternionMakeWithAngleAndAxis(xRadians, 1, 0, 0)
            glQuaternion = GLKQuaternionMultiply(glQuaternion, xMultiplier)

            // Perform side to side rotations around *WORLD* Y axis (note the order of multiplication, different from above)
            let yMultiplier = GLKQuaternionMakeWithAngleAndAxis(yRadians, 0, 1, 0)
            glQuaternion = GLKQuaternionMultiply(yMultiplier, glQuaternion)

            cameraNode.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)

            prevLocation = location
        }
    }

    @objc func handlePinch(pinchRec: UIPinchGestureRecognizer) {
        if pinchRec.numberOfTouches != 2 { return }

        let zoom = CGFloat(pinchRec.scale)
        switch pinchRec.state {
        case .began:
            startScale = cameraNode.camera!.fieldOfView
        case .changed:
            let fov = startScale / zoom
            if fov > minFoV && fov <= maxFoV {
                cameraNode.camera?.fieldOfView = fov
            }
        default:
            break
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != prevBounds.size.width || bounds.size.height != prevBounds.size.height {
            sceneView.setNeedsDisplay()
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // do not mix pan gestures with the others
        if (gestureRecognizer is UIPanGestureRecognizer) || (otherGestureRecognizer is UIPanGestureRecognizer) {
            return false
        }
        return true
    }
}

private extension CMDeviceMotion {
    func orientation() -> SCNVector4 {
        let attitude = self.attitude.quaternion
        let attitudeQuaternion = GLKQuaternion(quaternion: attitude)
        let result: SCNVector4

        switch UIApplication.shared.statusBarOrientation {
        case .landscapeRight:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(.pi / 2, 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi / 2), 1, 0, 0)
            var quaternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuaternion)
            quaternionMultiplier = GLKQuaternionMultiply(cq2, quaternionMultiplier)
            result = quaternionMultiplier.vector(for: .landscapeRight)
        case .landscapeLeft:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi / 2), 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi / 2), 1, 0, 0)
            var quaternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuaternion)
            quaternionMultiplier = GLKQuaternionMultiply(cq2, quaternionMultiplier)
            result = quaternionMultiplier.vector(for: .landscapeLeft)
        case .portraitUpsideDown:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi / 2), 1, 0, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1)
            var quaternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuaternion)
            quaternionMultiplier = GLKQuaternionMultiply(cq2, quaternionMultiplier)
            result = quaternionMultiplier.vector(for: .portraitUpsideDown)
        default:
            let clockwiseQuaternion = GLKQuaternionMakeWithAngleAndAxis(-(.pi / 2), 1, 0, 0)
            let quaternionMultiplier = GLKQuaternionMultiply(clockwiseQuaternion, attitudeQuaternion)
            result = quaternionMultiplier.vector(for: .portrait)
        }
        return result
    }
}

private extension UIView {
    func add(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let views = ["view": view]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: views)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)
        self.addConstraints(hConstraints)
        self.addConstraints(vConstraints)
    }
}

private extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }

    func toRadians() -> Self {
        return self * .pi / 180
    }
}

private extension GLKQuaternion {
    init(quaternion: CMQuaternion) {
        self.init(q: (Float(quaternion.x), Float(quaternion.y), Float(quaternion.z), Float(quaternion.w)))
    }

    func vector(for orientation: UIInterfaceOrientation) -> SCNVector4 {
        switch orientation {
        case .landscapeRight:
            return SCNVector4(x: -self.y, y: self.x, z: self.z, w: self.w)
        case .landscapeLeft:
            return SCNVector4(x: self.y, y: -self.x, z: self.z, w: self.w)
        case .portraitUpsideDown:
            return SCNVector4(x: -self.x, y: -self.y, z: self.z, w: self.w)
        default:
            return SCNVector4(x: self.x, y: self.y, z: self.z, w: self.w)
        }
    }
}

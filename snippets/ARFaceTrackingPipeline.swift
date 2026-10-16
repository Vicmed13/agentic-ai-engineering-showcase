Real-Time Spatial Geometry Extraction & SwiftUI Vector Canvas
import SwiftUI
#if !targetEnvironment(simulator)
import ARKit
import RealityKit
#endif

// MARK: - 1. AR Tracking Session State Machine (From ARSessionState.swift)

public enum ARSessionState: Equatable, Sendable {
    case active
    case paused
    case limited(String)
    case interrupted(String)
    case failed(String)
}

// MARK: - 2. Hardware Tracking & Simulator Fallback View (From ARFaceTracker.swift)

public struct ARFaceTracker: View {
    @Binding var sessionState: ARSessionState
    @Binding var facePoints: [Int: CGPoint]
    
    public init(sessionState: Binding<ARSessionState>, facePoints: Binding<[Int: CGPoint]>) {
        self._sessionState = sessionState
        self._facePoints = facePoints
    }
    
    public var body: some View {
        #if targetEnvironment(simulator)
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
                Text("AR Simulator Mode")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            sessionState = .active
            generateMockFacePoints()
        }
        #else
        ARCameraViewContainer(sessionState: $sessionState, facePoints: $facePoints)
        #endif
    }
    
    #if targetEnvironment(simulator)
    /// Real-time procedural mock face generator for local testing without hardware TrueDepth sensors
    private func generateMockFacePoints() {
        var mockPoints: [Int: CGPoint] = [:]
        let centerX: CGFloat = 200.0
        let centerY: CGFloat = 350.0
        
        for i in 0..<1220 {
            let angle = Double(i) * (2.0 * .pi / 1220.0)
            let radiusX: CGFloat = 120.0
            let radiusY: CGFloat = 160.0
            let x = centerX + radiusX * CGFloat(cos(angle))
            let y = centerY + radiusY * CGFloat(sin(angle))
            mockPoints[i] = CGPoint(x: x, y: y)
        }
        self.facePoints = mockPoints
    }
    #endif
}

// MARK: - 3. RealityKit + ARKit TrueDepth Coordinator (From ARFaceTracker.swift)

#if !targetEnvironment(simulator)
struct ARCameraViewContainer: UIViewRepresentable {
    @Binding var sessionState: ARSessionState
    @Binding var facePoints: [Int: CGPoint]
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        
        guard ARFaceTrackingConfiguration.isSupported else {
            DispatchQueue.main.async {
                self.sessionState = .failed("Face tracking is not supported on this device.")
            }
            return arView
        }
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARCameraViewContainer
        weak var arView: ARView?
        
        init(parent: ARCameraViewContainer) {
            self.parent = parent
        }
        
        // Exact SIMD4 Geometry Extraction & RealityKit Viewport Projection from your app
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            let vertices = faceAnchor.geometry.vertices
            let worldMatrix = faceAnchor.transform
            
            Task { @MainActor in
                guard let arView = self.arView else { return }
                var pointsMap: [Int: CGPoint] = [:]
                
                // Homogeneous 4D transform & 3D-to-2D viewport projection loop
                for (index, vertex) in vertices.enumerated() {
                    let worldPoint = worldMatrix * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1.0)
                    let world3D = simd_make_float3(worldPoint)
                    if let projected = arView.project(world3D) {
                        pointsMap[index] = CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
                    }
                }
                self.parent.facePoints = pointsMap
            }
        }
        
        // Tracking State & Interruption Recovery
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            Task { @MainActor in
                switch camera.trackingState {
                case .normal:
                    self.parent.sessionState = .active
                case .limited(let reason):
                    self.parent.sessionState = .limited("Tracking limited: \(reason)")
                case .notAvailable:
                    self.parent.sessionState = .failed("Tracking unavailable")
                }
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor in
                self.parent.sessionState = .interrupted("Tracking session interrupted.")
            }
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            Task { @MainActor in
                self.parent.sessionState = .active
            }
        }
    }
}
#endif

// MARK: - 4. 60 FPS Procedural Vector Overlay (From ARHUDOverlayView.swift)

public struct ARHUDVectorOverlay: View {
    @Binding var facePoints: [Int: CGPoint]
    let activeIndices: [Int]
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !facePoints.isEmpty else { return }
                
                let points = activeIndices.compactMap { facePoints[$0] }
                guard points.count >= 2 else { return }
                
                var path = Path()
                path.move(to: points[0])
                for pt in points.dropFirst() {
                    path.addLine(to: pt)
                }
                
                // Multi-pass glowing vector styling
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let progress = CGFloat(elapsed.truncatingRemainder(dividingBy: 2.5) / 2.5)
                let animatedPath = path.trimmedPath(from: 0, to: progress)
                
                context.stroke(
                    animatedPath,
                    with: .color(.yellow.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                context.stroke(
                    animatedPath,
                    with: .color(.yellow),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 6])
                )
            }
        }
        .allowsHitTesting(false)
    }
}

import SwiftUI
import SceneKit
import ImageIO

struct FrameSpec: Decodable {
    let id: String
    let scene: String
    let file: String
    let camera_to_world: [[Double]]
    let occlusion: Bool
    let distractor: Bool
}
struct SequenceSpec: Decodable {
    let width: Int
    let height: Int
    let intrinsics: [[Double]]
    let calibration_board_world: [Double]
    let threshold: Double
    let calibration: [FrameSpec]
    let scans: [FrameSpec]
}
struct FrameResult {
    let spec: FrameSpec
    let pixels: [Double]
    let points: [Double]
    let image: UIImage
}

final class ReplayModel: ObservableObject {
    @Published var message = "Extracting source frames and calibrating…"
    @Published var results: [FrameResult] = []
    @Published var plane: [Double] = []
    @Published var selected = 0
    @Published var showAll = true
    private var started = false

    func run() {
        guard !started else { return }; started = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let url = Bundle.main.url(forResource: "sequence", withExtension: "json", subdirectory: "fixtures") else { throw ReplayError.message("Missing sequence metadata") }
                let spec = try JSONDecoder().decode(SequenceSpec.self, from: Data(contentsOf: url))
                let K = spec.intrinsics.flatMap { $0 }
                var calibration: [Double] = []
                var output: [FrameResult] = []
                for frame in spec.calibration {
                    let (pixels, _) = try Self.extract(frame, spec)
                    let T = frame.camera_to_world.flatMap { $0 }
                    var xyz = [Double](repeating: 0, count: pixels.count / 2 * 3)
                    let n = laser_calibration_points(pixels, Int32(pixels.count / 2), K, T, spec.calibration_board_world, &xyz)
                    guard n >= 0 else { throw ReplayError.message("Calibration geometry rejected \(frame.id)") }
                    calibration += xyz.prefix(Int(n) * 3)
                }
                var fitted = [Double](repeating: 0, count: 4)
                guard laser_fit_plane(calibration, Int32(calibration.count / 3), &fitted) == 0 else { throw ReplayError.message("Degenerate calibration") }
                var records: [[String: Any]] = []
                for frame in spec.scans {
                    let (pixels, image) = try Self.extract(frame, spec)
                    let T = frame.camera_to_world.flatMap { $0 }
                    var xyz = [Double](repeating: 0, count: pixels.count / 2 * 3)
                    let n = laser_points(pixels, Int32(pixels.count / 2), K, fitted, T, &xyz)
                    guard n >= 0 else { throw ReplayError.message("Geometry rejected \(frame.id)") }
                    xyz = Array(xyz.prefix(Int(n) * 3))
                    output.append(FrameResult(spec: frame, pixels: pixels, points: xyz, image: image))
                    records.append(["id": frame.id, "pixels": Self.rows(pixels, 2), "points": Self.rows(xyz, 3)])
                }
                let evidence: [String: Any] = ["schema": 1, "core": "Accelerate C source compiled into this app", "calibration_points": calibration.count / 3, "calibration_plane": fitted, "frames": records, "poses": "Supplied synthetic camera-to-world poses; no tracker"]
                let destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("native-validation.json")
                try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted, .sortedKeys]).write(to: destination)
                DispatchQueue.main.async {
                    self.plane = fitted; self.results = output
                    self.message = "Calibrated \(calibration.count / 3) board points · computed \(output.count) frames"
                }
            } catch {
                DispatchQueue.main.async { self.message = "Replay failed: \(error.localizedDescription)" }
            }
        }
    }
    static func rows(_ values: [Double], _ width: Int) -> [[Double]] {
        stride(from: 0, to: values.count, by: width).map { Array(values[$0..<$0+width]) }
    }
    static func extract(_ frame: FrameSpec, _ spec: SequenceSpec) throws -> ([Double], UIImage) {
        guard let url = Bundle.main.url(forResource: frame.file, withExtension: nil, subdirectory: "fixtures"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == spec.width, image.height == spec.height else { throw ReplayError.message("Invalid source image \(frame.file)") }
        var bytes = [UInt8](repeating: 0, count: spec.width * spec.height)
        let rendered = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: spec.width, height: spec.height, bitsPerComponent: 8, bytesPerRow: spec.width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: spec.width, height: spec.height))
            return true
        }
        guard rendered else { throw ReplayError.message("Cannot decode source frame") }
        let floats = bytes.map { Float($0) }
        var pixels = [Double](repeating: 0, count: spec.width * 2)
        let n = laser_extract(floats, Int32(spec.width), Int32(spec.height), spec.threshold, &pixels)
        guard n >= 0 else { throw ReplayError.message("Extraction rejected \(frame.id)") }
        return (Array(pixels.prefix(Int(n) * 2)), UIImage(cgImage: image))
    }
}
enum ReplayError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

struct CloudView: UIViewRepresentable {
    let results: [FrameResult]
    let selected: Int
    let showAll: Bool
    let yaw: Float
    let pitch: Float
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(); view.backgroundColor = UIColor(red: 0.035, green: 0.055, blue: 0.09, alpha: 1)
        view.allowsCameraControl = false; view.autoenablesDefaultLighting = true
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {
        let scene = SCNScene()
        guard !results.isEmpty else { view.scene = scene; return }
        let selectedResult = results[min(selected, results.count - 1)]
        let frames = showAll && !selectedResult.spec.distractor ? results.filter { $0.spec.scene == selectedResult.spec.scene && !$0.spec.distractor } : [selectedResult]
        let allVertices: [SCNVector3] = frames.flatMap { frame in
            stride(from: 0, to: frame.points.count, by: 3).map {
                SCNVector3(frame.points[$0], -frame.points[$0 + 1], -frame.points[$0 + 2])
            }
        }
        guard !allVertices.isEmpty else { view.scene = scene; return }
        let low = SCNVector3(allVertices.map(\.x).min()!, allVertices.map(\.y).min()!, allVertices.map(\.z).min()!)
        let high = SCNVector3(allVertices.map(\.x).max()!, allVertices.map(\.y).max()!, allVertices.map(\.z).max()!)
        let center = SCNVector3((low.x + high.x) / 2, (low.y + high.y) / 2, (low.z + high.z) / 2)
        let radius = allVertices.map { vertex in
            sqrt(pow(vertex.x - center.x, 2) + pow(vertex.y - center.y, 2) + pow(vertex.z - center.z, 2))
        }.max()!
        let cloud = SCNNode(); cloud.eulerAngles = SCNVector3(pitch, yaw, 0)
        scene.rootNode.addChildNode(cloud)
        for (i, frame) in frames.enumerated() {
            let vertices: [SCNVector3] = stride(from: 0, to: frame.points.count, by: 3).map {
                // Display flips Y/Z for SceneKit and centers the cloud; stored data is unchanged.
                SCNVector3(Float(frame.points[$0]) - center.x, -Float(frame.points[$0 + 1]) - center.y, -Float(frame.points[$0 + 2]) - center.z)
            }
            let source = SCNGeometrySource(vertices: vertices)
            let indices = Array(0..<UInt32(vertices.count))
            let element = SCNGeometryElement(indices: indices, primitiveType: .point)
            element.pointSize = 4; element.minimumPointScreenSpaceRadius = 2; element.maximumPointScreenSpaceRadius = 5
            let geometry = SCNGeometry(sources: [source], elements: [element])
            let material = SCNMaterial(); material.lightingModel = .constant
            material.diffuse.contents = selectedResult.spec.distractor ? UIColor.systemOrange : UIColor(hue: CGFloat(i) / CGFloat(max(frames.count, 1)) * 0.4 + 0.45, saturation: 0.7, brightness: 1, alpha: 1)
            geometry.materials = [material]
            cloud.addChildNode(SCNNode(geometry: geometry))
        }
        let camera = SCNNode(); camera.camera = SCNCamera(); camera.camera?.fieldOfView = 45
        camera.camera?.zNear = 0.001; camera.camera?.zFar = 100
        // Fit a bounding sphere, leaving room for arbitrary rotation without clipping.
        let distance = max(0.1, radius / sin(Float.pi / 8) * 1.12)
        camera.position = SCNVector3(0, 0, distance); camera.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(camera); view.scene = scene; view.pointOfView = camera
    }
}

struct ContentView: View {
    @StateObject private var model = ReplayModel()
    @State private var yaw: Float = -0.35
    @State private var pitch: Float = 0.35
    @State private var dragYaw: Float = -0.35
    @State private var dragPitch: Float = 0.35
    @State private var rotating = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Freehand Laser Replay").font(.title2.bold())
                Text("Recovered stages · generated observations").font(.subheadline).foregroundStyle(.secondary)
                Text(model.message).font(.caption).accessibilityIdentifier("replay-status")
                if !model.results.isEmpty {
                    let frame = model.results[min(model.selected, model.results.count - 1)]
                    Picker("Frame", selection: $model.selected) {
                        ForEach(model.results.indices, id: \.self) { index in Text(model.results[index].spec.id).tag(index) }
                    }.pickerStyle(.menu).accessibilityIdentifier("frame-picker")
                    Image(uiImage: frame.image).resizable().interpolation(.none).aspectRatio(contentMode: .fit).frame(maxHeight: 200)
                        .overlay(alignment: .bottomLeading) { Text("SOURCE FRAME · 160 × 120").font(.caption2.monospaced()).padding(5).background(.black.opacity(0.7)).foregroundStyle(.white) }
                    Text("\(frame.pixels.count / 2) ridge samples → \(frame.points.count / 3) 3D points").font(.caption.monospaced())
                    Toggle("Accumulate this scene’s five views", isOn: $model.showAll).font(.caption)
                    CloudView(results: model.results, selected: model.selected, showAll: model.showAll, yaw: yaw, pitch: pitch)
                        .frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 12)).contentShape(Rectangle())
                        .highPriorityGesture(DragGesture(minimumDistance: 2).onChanged { value in
                            rotating = true
                            yaw = dragYaw + Float(value.translation.width) * 0.01
                            pitch = min(1.4, max(-1.4, dragPitch + Float(value.translation.height) * 0.01))
                        }.onEnded { _ in rotating = false; dragYaw = yaw; dragPitch = pitch })
                        .accessibilityIdentifier("point-cloud")
                    HStack {
                        Button("Rotate left") { yaw -= .pi / 8; dragYaw = yaw }
                        Spacer()
                        Button("Reset view") { yaw = -0.35; pitch = 0.35; dragYaw = yaw; dragPitch = pitch }
                        Spacer()
                        Button("Rotate right") { yaw += .pi / 8; dragYaw = yaw }
                    }.font(.caption)
                    Text("Drag inside the cloud to rotate. Colors identify views, not surface texture.").font(.caption2).foregroundStyle(.secondary)
                    if frame.spec.distractor { Text("FAILURE CASE: a bright non-laser ridge is accepted. Local filtering cannot identify its cause.").font(.caption).foregroundStyle(.orange) }
                    if frame.spec.occlusion { Text("Columns 65–85 have the laser occluded in the input image.").font(.caption) }
                } else { ProgressView() }
                Text("Camera poses and a metric calibration board are supplied by the simulator. This app computes its laser plane from six calibration PNGs, then extracts and triangulates the scan PNGs. It does not implement the historical proprietary camera tracker or test a real laser.").font(.caption).foregroundStyle(.secondary)
            }.padding()
        }.scrollDisabled(rotating).onAppear { model.run() }
    }
}
@main struct FreehandReplayApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

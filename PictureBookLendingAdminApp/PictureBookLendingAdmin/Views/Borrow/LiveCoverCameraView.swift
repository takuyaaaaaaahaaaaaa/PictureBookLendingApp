import AVFoundation
import CoreImage
import ImageIO
import SwiftUI

/// Samples upright, unmirrored frames with one recognition request in flight.
/// Rectangle detection is an optional part of recognition, never a capture gate.
struct LiveCoverCameraView: UIViewRepresentable {
    let onFrame: @MainActor (Data) async -> Bool
    let onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFrame: onFrame, onFailure: onFailure)
    }
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onOrientation = { context.coordinator.setOrientation($0) }
        context.coordinator.previewView = view
        context.coordinator.start()
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }
    final class PreviewView: UIView {
        var onOrientation: ((AVCaptureVideoOrientation) -> Void)?
        private var orientationTimer: Timer?
        private var lastOrientation: AVCaptureVideoOrientation?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            orientationTimer?.invalidate()
            orientationTimer = nil
            guard window != nil else { return }
            // A 180-degree rotation can leave bounds unchanged. Observe the scene's
            // settled orientation even when UIKit does not request another layout.
            let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
                self?.updateOrientation()
            }
            orientationTimer = timer
            RunLoop.main.add(timer, forMode: .common)
            updateOrientation()
        }
        deinit { orientationTimer?.invalidate() }
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        override func layoutSubviews() {
            super.layoutSubviews()
            updateOrientation()
        }
        private func updateOrientation() {
            let orientation: AVCaptureVideoOrientation
            switch window?.windowScene?.interfaceOrientation {
            case .landscapeLeft: orientation = .landscapeLeft
            case .landscapeRight: orientation = .landscapeRight
            case .portraitUpsideDown: orientation = .portraitUpsideDown
            default: orientation = .portrait
            }
            previewLayer.connection?.makeUpright(orientation)
            if lastOrientation != orientation {
                lastOrientation = orientation
                onOrientation?(orientation)
            }
        }
    }
    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private static let accessDeniedMessage = "設定アプリでカメラへのアクセスを許可してください。"
        let session = AVCaptureSession()
        weak var previewView: PreviewView?
        private let queue = DispatchQueue(label: "CoverLiveCamera")
        private let context = CIContext()
        private let onFrame: @MainActor (Data) async -> Bool
        private let onFailure: (String) -> Void
        private var orientation: AVCaptureVideoOrientation = .portrait
        private var outputConnection: AVCaptureConnection?
        private var lastFrameTime: CFTimeInterval = 0
        private var processing = false
        private var stopped = false

        init(onFrame: @escaping @MainActor (Data) async -> Bool,
             onFailure: @escaping (String) -> Void) {
            self.onFrame = onFrame
            self.onFailure = onFailure
        }
        func setOrientation(_ orientation: AVCaptureVideoOrientation) {
            queue.async {
                self.orientation = orientation
                if let connection = self.outputConnection, connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
            }
        }
        func start() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: queue.async { self.configureAndStart() }
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    if allowed { self.queue.async { self.configureAndStart() } }
                    else { self.fail(Self.accessDeniedMessage) }
                }
            default: fail(Self.accessDeniedMessage)
            }
        }
        func stop() {
            queue.async { self.halt() }
        }
        /// Must run on `queue`.
        private func halt() {
            stopped = true
            if session.isRunning { session.stopRunning() }
        }
        private func configureAndStart() {
            guard !stopped else { return }
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                fail("インナーカメラを開けませんでした。")
                return
            }
            session.beginConfiguration()
            session.sessionPreset = .high
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            guard session.canAddInput(input) else {
                session.commitConfiguration(); fail("カメラを開けませんでした。"); return
            }
            session.addInput(input)
            guard session.canAddOutput(output) else {
                session.commitConfiguration(); fail("カメラ映像を取得できませんでした。"); return
            }
            session.addOutput(output)
            outputConnection = output.connection(with: .video)
            // AVCapture rotates the pixel buffer itself, matching the preview orientation.
            outputConnection?.makeUpright(orientation)
            output.setSampleBufferDelegate(self, queue: queue)
            session.commitConfiguration()
            session.startRunning()
            DispatchQueue.main.async { self.previewView?.setNeedsLayout() }
        }
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            guard !stopped, !processing,
                  let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let now = CACurrentMediaTime()
            guard now - lastFrameTime >= 1 else { return }
            lastFrameTime = now
            var image = CIImage(cvPixelBuffer: buffer)
            let scale = min(1, 1024 / max(image.extent.width, image.extent.height))
            image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
            guard let frame = try? cgImage.encodedData(type: "public.jpeg", quality: 0.9) else { return }
            processing = true
            Task { @MainActor in
                let finished = await self.onFrame(frame)
                self.queue.async {
                    self.processing = false
                    if finished { self.halt() }
                }
            }
        }
        private func fail(_ message: String) {
            DispatchQueue.main.async { self.onFailure(message) }
        }
    }
}

private extension AVCaptureConnection {
    func makeUpright(_ orientation: AVCaptureVideoOrientation) {
        if isVideoOrientationSupported { videoOrientation = orientation }
        if isVideoMirroringSupported {
            automaticallyAdjustsVideoMirroring = false
            isVideoMirrored = false
        }
    }
}

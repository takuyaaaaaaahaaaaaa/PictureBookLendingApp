import AVFoundation
import CoreImage
import ImageIO
import SwiftUI

/// Samples upright, unmirrored frames with one recognition request in flight.
/// Rectangle detection is an optional part of recognition, never a capture gate.
struct LiveCoverCameraView: UIViewRepresentable {
    let onFrame: @MainActor @Sendable (Frame) async -> Bool
    struct Frame: Sendable {
        let data: Data
        let generation: UUID
        let isCurrent: @MainActor @Sendable () -> Bool
    }

    let onFailure: @MainActor @Sendable (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onFrame: { [onFrame] data in await onFrame(data) },
            onFailure: { [onFailure] message in onFailure(message) }
        )
    }
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onGeometry = { context.coordinator.setGeometry($0, orientation: $1) }
        context.coordinator.previewView = view
        context.coordinator.start()
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }
    final class PreviewView: UIView {
        var onGeometry: ((LiveCoverGeometry, AVCaptureVideoOrientation) -> Void)?
        private var lastGeometry: LiveCoverGeometry?
        private let guideLayer = CAShapeLayer()
        private let outlineLayer = CAShapeLayer()
        private let statusLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            for shape in [guideLayer, outlineLayer] {
                shape.fillColor = UIColor.clear.cgColor
                shape.strokeColor = UIColor.systemRed.cgColor
                shape.lineWidth = 3
                layer.addSublayer(shape)
            }
            guideLayer.lineDashPattern = [8, 6]
            statusLabel.textColor = .white
            statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            statusLabel.font = .preferredFont(forTextStyle: .caption1)
            statusLabel.adjustsFontForContentSizeCategory = true
            statusLabel.numberOfLines = 0
            addSubview(statusLabel)
            showOutline(nil, corrected: false)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func showOutline(_ points: [CGPoint]?, corrected: Bool) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let points, let first = points.first {
                let path = UIBezierPath()
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.close()
                outlineLayer.path = path.cgPath
            } else {
                outlineLayer.path = nil
            }
            CATransaction.commit()
            statusLabel.text =
                points == nil ? "枠内を検索中" : (corrected ? "輪郭の範囲を検索中・図書は未確定" : "四角い輪郭を検出・図書は未確定")
            layoutStatus()
        }

        private func layoutStatus() {
            let inset: CGFloat = 28
            let width = max(0, bounds.width - 2 * inset)
            let height = statusLabel.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            ).height
            statusLabel.frame = CGRect(
                x: inset, y: bounds.height - inset - height, width: width, height: height)
        }
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
            switch window?.windowScene?.effectiveGeometry.interfaceOrientation {
            case .landscapeLeft: orientation = .landscapeLeft
            case .landscapeRight: orientation = .landscapeRight
            case .portraitUpsideDown: orientation = .portraitUpsideDown
            default: orientation = .portrait
            }
            previewLayer.connection?.makeUpright(orientation)
            let geometry = LiveCoverGeometry(size: bounds.size)
            if lastOrientation != orientation || lastGeometry != geometry {
                lastOrientation = orientation
                lastGeometry = geometry
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                guideLayer.path = UIBezierPath(rect: geometry.guide).cgPath
                CATransaction.commit()
                showOutline(nil, corrected: false)
                onGeometry?(geometry, orientation)
            }
            layoutStatus()
        }
    }
    // AVFoundation calls the delegate on `queue`. Capture state is confined to that
    // queue (asserted at every internal entry); UI references/callbacks are MainActor.
    // This Objective-C delegate cannot express DispatchQueue isolation to Swift.
    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
        @unchecked Sendable
    {
        private static let accessDeniedMessage = "設定アプリでカメラへのアクセスを許可してください。"
        let session = AVCaptureSession()
        @MainActor weak var previewView: PreviewView?
        private let queue = DispatchQueue(label: "CoverLiveCamera")
        private var processor = LiveCoverFrameProcessor()
        @MainActor private var currentGeneration = UUID()
        @MainActor private var isActive = true
        private var generation = UUID()
        private var geometry: LiveCoverGeometry?
        private var acceptFramesAfter: CFTimeInterval = 0
        private let onFrame: @MainActor @Sendable (Frame) async -> Bool
        private let onFailure: @MainActor @Sendable (String) -> Void
        private var orientation: AVCaptureVideoOrientation = .portrait
        private var outputConnection: AVCaptureConnection?
        private var lastFrameTime: CFTimeInterval = 0
        private var processing = false
        private var stopped = false
        private let notificationCenter: NotificationCenter
        private var sessionObservers: [NSObjectProtocol] = []

        init(
            onFrame: @escaping @MainActor @Sendable (Frame) async -> Bool,
            onFailure: @escaping @MainActor @Sendable (String) -> Void,
            notificationCenter: NotificationCenter = .default
        ) {
            self.onFrame = onFrame
            self.onFailure = onFailure
            self.notificationCenter = notificationCenter
            super.init()
            // Session-specific observers also cover errors emitted by startRunning().
            // Retry creates a fresh coordinator; this session never restarts itself.
            sessionObservers = [
                notificationCenter.addObserver(
                    forName: AVCaptureSession.runtimeErrorNotification,
                    object: session, queue: nil
                ) { [weak self] _ in
                    self?.fail("カメラが停止しました。「もう一度探す」で再開してください。")
                },
                notificationCenter.addObserver(
                    forName: AVCaptureSession.wasInterruptedNotification,
                    object: session, queue: nil
                ) { [weak self] _ in
                    self?.fail("カメラの使用が中断されました。再び利用できる状態で「もう一度探す」を押してください。")
                },
            ]
        }
        deinit {
            for observer in sessionObservers { notificationCenter.removeObserver(observer) }
        }
        @MainActor
        func setGeometry(_ geometry: LiveCoverGeometry, orientation: AVCaptureVideoOrientation) {
            currentGeneration = UUID()
            let generation = currentGeneration
            queue.async {
                self.generation = generation
                self.geometry = geometry
                self.orientation = orientation
                self.outputConnection?.makeUpright(orientation)
                self.processor.reset()
                self.lastFrameTime = 0
                // Discard frames captured before the output rotation/layout change.
                self.acceptFramesAfter = CACurrentMediaTime()
            }
        }
        func start() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: queue.async { self.configureAndStart() }
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    if allowed {
                        self.queue.async { self.configureAndStart() }
                    } else {
                        self.fail(Self.accessDeniedMessage)
                    }
                }
            default: fail(Self.accessDeniedMessage)
            }
        }
        @MainActor func stop() {
            isActive = false
            currentGeneration = UUID()
            previewView?.showOutline(nil, corrected: false)
            queue.async { self.halt() }
        }
        /// Must run on `queue`.
        private func halt() {
            dispatchPrecondition(condition: .onQueue(queue))
            stopped = true
            for observer in sessionObservers { notificationCenter.removeObserver(observer) }
            sessionObservers.removeAll()
            if session.isRunning { session.stopRunning() }
        }
        private func configureAndStart() {
            dispatchPrecondition(condition: .onQueue(queue))
            guard !stopped else { return }
            guard
                let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .front),
                let input = try? AVCaptureDeviceInput(device: camera)
            else {
                fail("インナーカメラを開けませんでした。")
                return
            }
            session.beginConfiguration()
            session.sessionPreset = .high
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                fail("カメラを開けませんでした。")
                return
            }
            session.addInput(input)
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                fail("カメラ映像を取得できませんでした。")
                return
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
        func captureOutput(
            _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            dispatchPrecondition(condition: .onQueue(queue))
            guard !stopped, !processing, let geometry,
                CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    >= acceptFramesAfter,
                let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }
            let now = CACurrentMediaTime()
            guard now - lastFrameTime >= 1 else { return }
            lastFrameTime = now
            let image = CIImage(cvPixelBuffer: buffer)
            guard let result = processor.process(image, geometry: geometry),
                let data = try? result.image.encodedData(type: "public.jpeg", quality: 0.9)
            else { return }
            let points = result.outline?.points.map {
                geometry.previewPoint($0, crop: result.crop, imageSize: image.extent.size)
            }
            let corrected = result.isCorrected
            let generation = generation
            processing = true
            Task { @MainActor in
                let isCurrent: @MainActor @Sendable () -> Bool = { [weak self] in
                    guard let self else { return false }
                    return self.isActive && self.currentGeneration == generation
                }
                var finished = false
                if isCurrent() {
                    self.previewView?.showOutline(points, corrected: corrected)
                    finished = await self.onFrame(
                        Frame(data: data, generation: generation, isCurrent: isCurrent))
                }
                let shouldHalt = finished && isCurrent()
                self.queue.async {
                    self.processing = false
                    if shouldHalt { self.halt() }
                }
            }
        }
        private func fail(_ message: String) {
            queue.async {
                guard !self.stopped else { return }
                self.halt()
                DispatchQueue.main.async {
                    guard self.isActive else { return }
                    self.isActive = false
                    self.currentGeneration = UUID()
                    self.previewView?.showOutline(nil, corrected: false)
                    self.onFailure(message)
                }
            }
        }
    }
}

extension AVCaptureConnection {
    fileprivate func makeUpright(_ orientation: AVCaptureVideoOrientation) {
        if isVideoOrientationSupported { videoOrientation = orientation }
        if isVideoMirroringSupported {
            automaticallyAdjustsVideoMirroring = false
            isVideoMirrored = false
        }
    }
}

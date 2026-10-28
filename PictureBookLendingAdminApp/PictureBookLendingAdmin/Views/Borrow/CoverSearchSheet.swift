import AVFoundation
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingUI
import SwiftUI
import UIKit

/// Suggestions only; selecting a candidate continues into the existing loan flow.
struct CoverSearchSheet: View {
    @Environment(\.analytics) private var analytics
    @State private var telemetry = CoverSearchTelemetry()
    let books: [Book]
    let onSelect: (Book) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var matches: [CoverMatch] = []
    @State private var errorMessage: String?
    @State private var capturedPreview: UIImage?
    @State private var isLiveScanning = true
    @State private var scanAttempt = 0
    @State private var confirmation = LiveCoverConfirmation()
    @State private var frameGeneration: UUID?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide =
                    geometry.size.width >= 760 && geometry.size.width > geometry.size.height
                    && !dynamicTypeSize.isAccessibilitySize
                let layout =
                    wide
                    ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(spacing: 16))
                layout {
                    cameraPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(
                            height: wide
                                ? nil
                                : max(
                                    120,
                                    (geometry.size.height - 32) * (matches.isEmpty ? 0.65 : 0.48)))
                    resultsPanel
                        .frame(width: wide ? min(380, geometry.size.width * 0.34) : nil)
                        .frame(maxWidth: wide ? nil : .infinity, maxHeight: .infinity)
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("枠に表紙を合わせてください")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("閉じる", systemImage: "xmark", role: .closeIfAvailable) { dismiss() }
            }
            .onAppear {
                if !CameraUtility.isCameraAvailable { recordFailure(.camera) }
            }
            .onDisappear {
                if let event = telemetry.finish(selected: false) { analytics.track(event) }
                isLiveScanning = false
                scanAttempt += 1
            }
        }
    }

    private enum CandidateLayout {
        static let coverSize: CGFloat = 64
    }

    private var cameraPanel: some View {
        ZStack {
            Color.black
            if CameraUtility.isCameraAvailable && isLiveScanning {
                let currentAttempt = scanAttempt
                LiveCoverCameraView(
                    onFrame: { data in await searchLive(data, attempt: currentAttempt) },
                    onFailure: { message in
                        guard isCurrent(currentAttempt) else { return }
                        isLiveScanning = false
                        errorMessage = message
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        recordFailure(
                            status == .denied || status == .restricted ? .permission : .camera)
                    }
                )
                .id(scanAttempt)
                .accessibilityLabel("固定枠の内側だけを検索するカメラ")
            } else if let capturedPreview {
                Image(uiImage: capturedPreview).resizable().scaledToFit()
                    .accessibilityLabel("候補検索に使った表紙の写真")
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder").font(.system(size: 44))
                    Text(CameraUtility.isCameraAvailable ? "カメラを停止しています" : "カメラを利用できません")
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var resultsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage {
                    Text("検索できませんでした").font(.title3.bold())
                    Text(errorMessage).foregroundStyle(.secondary)
                } else if matches.isEmpty {
                    Label("破線の枠に表紙を合わせてください", systemImage: "viewfinder")
                        .font(.headline)
                    Text(
                        "実線は四角い輪郭の検出を示し、図書の特定ではありません。輪郭が見つからなくても枠内を検索します。少し止めても候補が出ない場合は、閉じてタイトル・著者で検索できます。"
                    )
                    .foregroundStyle(.secondary)
                } else {
                    Text("この本ですか？").font(.title2.bold())
                    Text("同じ表紙の本は、管理番号を確認して選んでください。")
                        .font(.callout).foregroundStyle(.secondary)
                    ForEach(matches) { match in
                        if let book = books.first(where: { $0.id == match.id }) {
                            Button {
                                if let event = telemetry.finish(selected: true) {
                                    analytics.track(event)
                                }
                                onSelect(book)
                            } label: {
                                HStack(spacing: 12) {
                                    BookImageView(imageURL: book.resolvedSmallImageSource) {
                                        Image(systemName: "book.closed").font(.title)
                                    }
                                    .aspectRatio(contentMode: .fit)
                                    .frame(
                                        width: CandidateLayout.coverSize,
                                        height: CandidateLayout.coverSize)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(book.title).font(.headline)
                                        if let number = book.managementNumber {
                                            Text("管理番号: \(number)").font(.subheadline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right")
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    Color(uiColor: .secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !isLiveScanning && CameraUtility.isCameraAvailable {
                    Button("もう一度探す", systemImage: "arrow.clockwise") { restart() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    private func recordFailure(_ reason: AnalyticsEvent.CoverFailure) {
        if let event = telemetry.fail(reason) { analytics.track(event) }
    }

    private func restart() {
        matches = []
        capturedPreview = nil
        errorMessage = nil
        confirmation = LiveCoverConfirmation()
        frameGeneration = nil
        scanAttempt += 1
        isLiveScanning = true
    }
    @MainActor
    private func searchLive(_ frame: LiveCoverCameraView.Frame, attempt: Int) async -> Bool {
        guard isCurrent(attempt), frame.isCurrent() else { return false }
        if frameGeneration != frame.generation {
            frameGeneration = frame.generation
            confirmation = LiveCoverConfirmation()
        }
        do {
            let candidates = try await CoverRecognitionService.shared.search(
                imageData: frame.data, books: books, detectCover: false)
            guard isCurrent(attempt), frame.isCurrent() else { return false }
            telemetry.didSearch()
            if confirmation.accept(candidates.first?.id) {
                matches = candidates
                if let event = telemetry.showCandidates(count: candidates.count) {
                    analytics.track(event)
                }
                errorMessage = nil
                isLiveScanning = false
                capturedPreview = UIImage(data: frame.data)
                return true
            }
            return false
        } catch {
            guard isCurrent(attempt), frame.isCurrent() else { return false }
            recordFailure(.recognition)
            errorMessage = error.localizedDescription
            isLiveScanning = false
            return true
        }
    }
    private func isCurrent(_ attempt: Int) -> Bool {
        isLiveScanning && attempt == scanAttempt
    }
}

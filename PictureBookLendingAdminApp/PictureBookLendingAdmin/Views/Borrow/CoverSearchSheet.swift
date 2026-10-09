import PictureBookLendingDomain
import PictureBookLendingUI
import SwiftUI
import UIKit

/// Suggestions only; selecting a candidate continues into the existing loan flow.
struct CoverSearchSheet: View {
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

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 760 && geometry.size.width > geometry.size.height
                    && !dynamicTypeSize.isAccessibilitySize
                let layout = wide ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(spacing: 16))
                layout {
                    cameraPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: wide ? nil : max(120, (geometry.size.height - 32) * (matches.isEmpty ? 0.65 : 0.48)))
                    resultsPanel
                        .frame(width: wide ? min(380, geometry.size.width * 0.34) : nil)
                        .frame(maxWidth: wide ? nil : .infinity, maxHeight: .infinity)
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("絵本の表紙をうつしてください")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onDisappear {
                isLiveScanning = false
                scanAttempt += 1
            }
        }
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
                    }
                )
                .id(scanAttempt)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.8), lineWidth: 2)
                        .padding(24)
                }
                .accessibilityLabel("表紙を検知するカメラ")
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
                    Label("表紙を中央に大きく映してください", systemImage: "viewfinder")
                        .font(.headline)
                    Text("少し止めると候補が表示されます。見つからない場合は、この画面を閉じてタイトル・著者で検索できます。")
                        .foregroundStyle(.secondary)
                } else {
                    Text("この本ですか？").font(.title2.bold())
                    Text("同じ表紙の本は、管理番号を確認して選んでください。")
                        .font(.callout).foregroundStyle(.secondary)
                    ForEach(matches) { match in
                        if let book = books.first(where: { $0.id == match.id }) {
                            Button { onSelect(book) } label: {
                                HStack(spacing: 12) {
                                    BookImageView(imageURL: book.resolvedSmallImageSource) {
                                        Image(systemName: "book.closed").font(.title)
                                    }
                                    .frame(width: 56, height: 76)
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
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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

    private func restart() {
        matches = []
        capturedPreview = nil
        errorMessage = nil
        confirmation = LiveCoverConfirmation()
        scanAttempt += 1
        isLiveScanning = true
    }
    @MainActor
    private func searchLive(_ data: Data, attempt: Int) async -> Bool {
        guard isCurrent(attempt) else { return true }
        do {
            let candidates = try await CoverRecognitionService.shared.search(
                imageData: data, books: books, detectCover: true)
            guard isCurrent(attempt) else { return true }
            if confirmation.accept(candidates.first?.id) {
                matches = candidates
                errorMessage = nil
                isLiveScanning = false
                capturedPreview = UIImage(data: data)
                return true
            }
            return false
        } catch {
            guard isCurrent(attempt) else { return true }
            errorMessage = error.localizedDescription
            isLiveScanning = false
            return true
        }
    }
    private func isCurrent(_ attempt: Int) -> Bool {
        isLiveScanning && attempt == scanAttempt
    }
}

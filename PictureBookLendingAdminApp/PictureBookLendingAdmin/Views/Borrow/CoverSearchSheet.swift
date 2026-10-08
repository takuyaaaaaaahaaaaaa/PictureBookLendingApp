import PhotosUI
import PictureBookLendingDomain
import PictureBookLendingUI
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
/// Cover recognition only suggests a book. The existing borrower and slot flow confirms the loan.
struct CoverSearchSheet: View {
    let books: [Book]
    let onSelect: (Book) -> Void
    let onManualSearch: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var photo: PhotosPickerItem?
    @State private var matches: [CoverMatch] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    #if canImport(UIKit)
        @State private var isCameraPresented = false
    #endif
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("絵本の表紙を写してください")
                        .font(.title2.bold())
                    Text("画像から登録済みの図書を探します。候補を確認してから貸出へ進みます。")
                        .foregroundStyle(.secondary)
                    #if canImport(UIKit)
                        if CameraUtility.isCameraAvailable {
                            Button("カメラで表紙を撮る", systemImage: "camera") {
                                isCameraPresented = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    #endif
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label("写真から表紙を選ぶ", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                    if isSearching {
                        ProgressView("表紙を探しています")
                    } else if let errorMessage {
                        ContentUnavailableView(
                            "検索できませんでした", systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage))
                    } else if hasSearched && matches.isEmpty {
                        ContentUnavailableView(
                            "候補が見つかりません", systemImage: "book.closed",
                            description: Text("タイトルや著者で探してください"))
                    } else if !matches.isEmpty {
                        Text("似ている図書の候補")
                            .font(.headline)
                        Text("表紙だけでは同じ本の複本を区別できません。管理番号を確認してください。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(matches) { match in
                            if let book = books.first(where: { $0.id == match.id }) {
                                Button {
                                    onSelect(book)
                                } label: {
                                    HStack(spacing: 12) {
                                        BookImageView(imageURL: book.resolvedSmallImageSource) {
                                            Image(systemName: "book.closed")
                                        }
                                        .frame(width: 50, height: 70)
                                        VStack(alignment: .leading) {
                                            Text(book.title).font(.headline)
                                            if let number = book.managementNumber {
                                                Text("管理番号: \(number)")
                                                    .font(.caption)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding()
                                    .background(
                                        .regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Button("タイトル・著者で手動検索", systemImage: "magnifyingglass") {
                        onManualSearch()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("表紙から探す")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onChange(of: photo) { _, selected in
                guard let selected else { return }
                Task {
                    guard let data = try? await selected.loadTransferable(type: Data.self) else {
                        errorMessage = "写真を読み込めませんでした"
                        return
                    }
                    await search(data)
                }
            }
            #if canImport(UIKit)
                .sheet(isPresented: $isCameraPresented) {
                    CameraImagePickerView(
                        onImagePicked: { image in
                            isCameraPresented = false
                            if let data = image.jpegData(compressionQuality: 0.9) {
                                Task { await search(data) }
                            } else {
                                errorMessage = "撮影画像を読み込めませんでした"
                            }
                        },
                        onCancel: { isCameraPresented = false }
                    )
                }
            #endif
        }
    }
    private func search(_ data: Data) async {
        isSearching = true
        errorMessage = nil
        matches = []
        defer {
            isSearching = false
            hasSearched = true
        }
        do {
            matches = try await CoverRecognitionService.shared.search(imageData: data, books: books)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

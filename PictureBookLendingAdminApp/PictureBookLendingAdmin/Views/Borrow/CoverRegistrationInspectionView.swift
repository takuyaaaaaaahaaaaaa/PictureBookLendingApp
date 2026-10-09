import PictureBookLendingUI
#if DEBUG
import PictureBookLendingDomain
import SwiftUI
import UIKit

/// Inspection is read-only; saving an explicit crop updates only the selected book.
struct CoverRegistrationInspectionView: View {
    let books: [Book]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("本を選んで切り抜きを確認できます。「範囲を修正」で保存すると、その本だけ検索準備を更新します。元の登録画像は残ります。外部の書影は公開URLから再取得します。")
                        .font(.callout)
                }
                Section("確認する本") {
                    ForEach(books.sorted { $0.title < $1.title }) { book in
                        NavigationLink(book.title) {
                            CoverRegistrationInspectionDetail(book: book)
                        }
                    }
                }
            }
            .navigationTitle("登録画像の検証")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", role: .closeIfAvailable) { dismiss() }
                }
            }
        }
    }
}

private struct CoverRegistrationInspectionDetail: View {
    let book: Book
    @State private var inspection: CoverRegistrationInspection?
    @State private var failure: String?
    @State private var editingCrop = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let inspection {
                    Button("範囲を修正", systemImage: "crop") { editingCrop = true }
                        .buttonStyle(.borderedProminent)
                    if inspection.manualRect != nil {
                        Text("この本は手動で指定した範囲だけを使って照合します。")
                            .foregroundStyle(.green)
                    }
                    Text("保存済みの索引は特徴量のみです。以下は現在の画像からの再現で、登録時の画像そのものを保存した記録ではありません。")
                        .font(.callout)
                    Text(inspection.sourceMatchesIndex
                         ? "画像の参照先は索引と一致しています。"
                         : "画像の参照先が索引と異なるか、索引がありません。")
                        .font(.callout)
                    if inspection.isRemote && inspection.manualRect == nil {
                        Text("外部書影は表紙検出をせず、元画像から特徴量を作成します。URLが同じでも画像が更新されている可能性があります。")
                            .font(.callout)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), alignment: .top)], alignment: .leading, spacing: 24) {
                        imagePanel("① 現在の元画像", data: inspection.sourceImage)
                        imagePanel("② 元画像からモデルへ渡す画像（256×256）", data: inspection.originalModelInput)
                        if let cropped = inspection.rectifiedImage {
                            imagePanel(inspection.manualRect != nil ? "③ 手動で指定した画像" : "③ 四角形検出で補正した画像", data: cropped)
                        }
                        if let input = inspection.rectifiedModelInput {
                            imagePanel("④ 補正側からモデルへ渡す画像（256×256）", data: input)
                        }
                    }
                    if !inspection.isRemote && inspection.rectifiedImage == nil {
                        Text("四角形を検出できなかったため、補正側も元画像を使用しています。")
                    }
                    Text("②・④は画像の中央を正方形に切り出した入力です。表紙の上下、文字や絵柄が欠けていないかを確認してください。")
                    Text("保存済み特徴量との再計算一致度")
                        .font(.headline)
                    Text("元画像側: \(score(inspection.originalSimilarity))")
                    if !inspection.isRemote || inspection.manualRect != nil {
                        Text("補正側: \(score(inspection.rectifiedSimilarity))")
                    }
                    Text("1に近いほど保存済み特徴量と似ています。本の認識精度を示す値ではありません。切り抜きが誤っていても高くなる場合があります。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let failure {
                    ContentUnavailableView("画像を確認できません", systemImage: "photo", description: Text(failure))
                } else {
                    ProgressView("登録画像を確認しています")
                }
            }
            .padding()
        }
        .navigationTitle(book.title)
        .sheet(isPresented: $editingCrop) {
            if let inspection {
                ManualCoverCropEditor(book: book, inspection: inspection) { updated in
                    self.inspection = updated
                }
            }
        }
        .task(id: book.id) {
            do {
                inspection = try await CoverRecognitionService.shared.inspectRegistration(book)
            } catch {
                failure = error.localizedDescription
            }
        }
    }

    private func score(_ value: Float?) -> String {
        value.map { String(format: "%.6f", $0) } ?? "比較する索引なし"
    }

    private func imagePanel(_ title: String, data: Data) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(.gray.opacity(0.12))
                    .accessibilityLabel(title)
            }
        }
    }
}

private struct ManualCoverCropEditor: View {
    let book: Book
    let inspection: CoverRegistrationInspection
    let onSaved: (CoverRegistrationInspection) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var left: Double
    @State private var top: Double
    @State private var right: Double
    @State private var bottom: Double
    @State private var saving = false
    @State private var failure: String?

    init(book: Book, inspection: CoverRegistrationInspection,
         onSaved: @escaping (CoverRegistrationInspection) -> Void) {
        self.book = book
        self.inspection = inspection
        self.onSaved = onSaved
        let rect = inspection.manualRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        _left = State(initialValue: rect.minX)
        _top = State(initialValue: rect.minY)
        _right = State(initialValue: rect.maxX)
        _bottom = State(initialValue: rect.maxY)
    }
    private var rect: CGRect { CGRect(x: left, y: top, width: right-left, height: bottom-top) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("四隅の丸を動かして表紙を囲んでください。下のスライダーでも調整できます。")
                    if let image = UIImage(data: inspection.sourceImage) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .overlay {
                                GeometryReader { geometry in
                                    let size = geometry.size
                                    let selection = CGRect(x: left * size.width, y: top * size.height,
                                        width: (right-left) * size.width, height: (bottom-top) * size.height)
                                    Path { path in
                                        path.addRect(CGRect(origin: .zero, size: size))
                                        path.addRect(selection)
                                    }.fill(.black.opacity(0.45), style: FillStyle(eoFill: true))
                                    Path { $0.addRect(selection) }.stroke(.white, lineWidth: 2)
                                    ForEach(0..<4) { corner in
                                        Circle().fill(.blue).frame(width: 28, height: 28)
                                            .overlay(Circle().stroke(.white, lineWidth: 2))
                                            .position(x: (corner % 2 == 0 ? left : right) * size.width,
                                                      y: (corner < 2 ? top : bottom) * size.height)
                                            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("cropSurface"))
                                                .onChanged { value in
                                                    let x = min(1, max(0, value.location.x / size.width))
                                                    let y = min(1, max(0, value.location.y / size.height))
                                                    if corner % 2 == 0 { left = min(x, right - 0.05) }
                                                    else { right = max(x, left + 0.05) }
                                                    if corner < 2 { top = min(y, bottom - 0.05) }
                                                    else { bottom = max(y, top + 0.05) }
                                                })
                                            .accessibilityHidden(true)
                                    }
                                }.coordinateSpace(name: "cropSurface")
                            }
                            .frame(maxHeight: 420)
                    }
                    VStack {
                        edge("左", value: $left, range: 0...(right-0.05))
                        edge("右", value: $right, range: (left+0.05)...1)
                        edge("上", value: $top, range: 0...(bottom-0.05))
                        edge("下", value: $bottom, range: (top+0.05)...1)
                    }
                    Text("指定範囲からこの本の特徴量だけを更新します。元の登録画像は変更しません。斜めの表紙の台形補正には対応していません。")
                        .font(.caption).foregroundStyle(.secondary)
                    if let failure { Text(failure).foregroundStyle(.red) }
                    Button {
                        saving = true
                        Task {
                            do {
                                try await CoverRecognitionService.shared.saveManualCrop(book,
                                    imageData: inspection.sourceImage, source: inspection.sourceIdentity, rect: rect)
                                let updated = try await CoverRecognitionService.shared.inspectRegistration(book)
                                onSaved(updated)
                                dismiss()
                            } catch { failure = error.localizedDescription }
                            saving = false
                        }
                    } label: {
                        if saving { ProgressView("検索準備を更新しています") }
                        else { Text("この範囲で検索準備を更新") }
                    }.buttonStyle(.borderedProminent)
                }.padding(24).disabled(saving)
            }
            .navigationTitle("表紙の範囲を修正")
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", role: .cancel) { dismiss() }.disabled(saving)
            } }
            .interactiveDismissDisabled(saving)
        }
    }
    private func edge(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label).frame(width: 30)
            Slider(value: value, in: range).accessibilityLabel(label + "の端")
        }
    }
}
#endif

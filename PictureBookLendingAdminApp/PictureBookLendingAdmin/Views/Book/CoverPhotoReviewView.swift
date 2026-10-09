import SwiftUI
import UIKit

/// A photo is not handed back to the form until the user explicitly approves the preview.
struct CoverPhotoReviewView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onRetake: () -> Void
    let onCancel: () -> Void
    var adjustingExistingPhoto = false
    @State private var sourceData: Data?
    @State private var previewData: Data?
    @State private var corners = CoverPhotoCorners.fullImage
    @State private var detected = false
    @State private var editing = false
    @State private var selectedCorner = 0
    @State private var busy = true
    @State private var failure: String?
    private let names = ["左上", "右上", "右下", "左下"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("表紙検索に使う写真です。机や手など余計なものが入らないように切り抜いてください。")
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    Text(editing ? "四隅を表紙に合わせてください" : "表紙全体が入っていますか？")
                        .font(.title2.bold())
                    Text(editing
                         ? "丸を動かすか、調整する角を選んでスライダーを動かします。"
                         : "文字や絵が欠けていないか、机や手が余分に入っていないか確認してください。")
                        .foregroundStyle(.secondary)
                    if busy {
                        ProgressView("表紙を準備しています")
                            .frame(maxWidth: .infinity, minHeight: 250)
                    } else if editing, let sourceData, let source = UIImage(data: sourceData) {
                        Image(uiImage: source).resizable().scaledToFit()
                            .overlay {
                                GeometryReader { geometry in
                                    let size = geometry.size
                                    Path { path in
                                        path.addRect(CGRect(origin: .zero, size: size))
                                        path.addPath(cropOutline(size))
                                    }.fill(.black.opacity(0.5), style: FillStyle(eoFill: true))
                                    cropOutline(size).stroke(.white, lineWidth: 2)
                                    ForEach(0..<4) { i in
                                        Circle().fill(selectedCorner == i ? Color.orange : Color.blue)
                                            .frame(width: 32, height: 32)
                                            .overlay(Circle().stroke(.white, lineWidth: 2))
                                            .position(scaled(corners.points[i], size))
                                            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("photoReview"))
                                                .onChanged { value in
                                                    selectedCorner = i
                                                    corners = corners.moving(i, to: CGPoint(
                                                        x: value.location.x / size.width, y: value.location.y / size.height))
                                                })
                                            .accessibilityHidden(true)
                                    }
                                }.coordinateSpace(name: "photoReview")
                            }
                            .frame(maxHeight: 430)
                            .padding(16)
                        Picker("調整する角", selection: $selectedCorner) {
                            ForEach(0..<4) { Text(names[$0]).tag($0) }
                        }.pickerStyle(.segmented)
                        HStack { Text("左右"); Slider(value: coordinate(x: true), in: 0...1).accessibilityLabel("角の左右位置") }
                        HStack { Text("上下"); Slider(value: coordinate(x: false), in: 0...1).accessibilityLabel("角の上下位置") }
                        Button("写真全体に戻す") { corners = .fullImage }
                        Button("切り抜きを確認") { render() }
                            .buttonStyle(.borderedProminent)
                    } else if let previewData, let preview = UIImage(data: previewData) {
                        Image(uiImage: preview).resizable().scaledToFit()
                            .frame(maxWidth: .infinity).frame(height: 420)
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("切り抜き後の表紙")
                        if !detected {
                            Text("表紙の範囲を自動で判断できませんでした。必要に応じて範囲を調整してください。")
                                .font(.callout)
                        }
                        HStack {
                            Button("範囲を調整", systemImage: "crop") { editing = true }
                                .buttonStyle(.bordered)
                            Spacer()
                            Button("この表紙を使う", systemImage: "checkmark") { onConfirm(preview) }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    if let failure { Text(failure).foregroundStyle(.red) }
                    if !adjustingExistingPhoto {
                        Button("撮り直す", systemImage: "camera", action: onRetake)
                            .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(editing ? "切り抜き範囲を調整" : "表紙の切り抜きを確認")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", role: .cancel, action: onCancel)
                }
            }
            .interactiveDismissDisabled(busy)
            .task {
                do {
                    let data = try CoverPhotoProcessor.normalizedData(image)
                    sourceData = data
                    if adjustingExistingPhoto {
                        editing = true
                        busy = false
                        return
                    }
                    let proposal = try await CoverPhotoProcessor.shared.propose(data)
                    guard !Task.isCancelled else { return }
                    corners = proposal.corners
                    detected = proposal.detected
                    previewData = proposal.previewData
                } catch { failure = error.localizedDescription }
                busy = false
            }
        }
    }
    private func cropOutline(_ size: CGSize) -> Path {
        Path { path in
            path.move(to: scaled(corners.points[0], size))
            for point in corners.points.dropFirst() { path.addLine(to: scaled(point, size)) }
            path.closeSubpath()
        }
    }
    private func scaled(_ point: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
    private func coordinate(x: Bool) -> Binding<Double> {
        Binding(get: { x ? corners.points[selectedCorner].x : corners.points[selectedCorner].y }, set: { value in
            var point = corners.points[selectedCorner]
            if x { point.x = value } else { point.y = value }
            corners = corners.moving(selectedCorner, to: point)
        })
    }
    private func render() {
        guard let sourceData else { return }
        busy = true
        failure = nil
        Task {
            do {
                previewData = try await CoverPhotoProcessor.shared.render(sourceData, corners: corners)
                editing = false
                detected = true
            } catch { failure = error.localizedDescription }
            busy = false
        }
    }
}

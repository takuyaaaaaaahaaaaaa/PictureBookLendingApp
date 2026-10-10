#if DEBUG
    import PictureBookLendingUI
    import SwiftUI

    /// 本番と同じカードの幅・長い姓名・状態・Dynamic Typeを確認する見本。
    struct BorrowerCardCatalogView: View {
        @State private var cardWidth: CGFloat = 240
        @State private var largeText = false
        @State private var showsDisclosure = false

        private static let samples = [
            BorrowerRowDisplay(id: UUID(), name: "あおき はると", isGuardian: false, isOverdue: false),
            BorrowerRowDisplay(
                id: UUID(), name: "むしゃのこうじ しゅんいちろう", isGuardian: false, isOverdue: false),
            BorrowerRowDisplay(id: UUID(), name: "いとう さくら", isGuardian: false, isOverdue: true),
            BorrowerRowDisplay(id: UUID(), name: "さとう さくらこ", isGuardian: true, isOverdue: false),
            BorrowerRowDisplay(
                id: UUID(), name: "かわばた りょうすけ", isGuardian: false, isOverdue: false,
                hasNoOpenSlot: true),
            BorrowerRowDisplay(
                id: UUID(), name: "てすとのながいみょうじ てすとのながいなまえ",
                isGuardian: true, isOverdue: true),
            BorrowerRowDisplay(
                id: UUID(), name: "こばやし そういちろう", isGuardian: true, isOverdue: false,
                hasNoOpenSlot: true),
        ]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("カード幅", selection: $cardWidth) {
                        Text("240pt").tag(CGFloat(240))
                        Text("340pt").tag(CGFloat(340))
                        Text("480pt").tag(CGFloat(480))
                    }
                    .pickerStyle(.menu)
                    Toggle("大きい文字（AX3）", isOn: $largeText)
                    Toggle("貸出の矢印", isOn: $showsDisclosure)
                    Text("保存なし・本番と共通のカード／端末の利用可能幅を超えない範囲で表示")
                        .font(.caption)
                    ForEach(Self.samples) { row in
                        BorrowerCardView(row: row, showsDisclosureIndicator: showsDisclosure)
                            .frame(maxWidth: cardWidth, alignment: .leading)
                            .dynamicTypeSize(largeText ? .accessibility3 : .large)
                    }
                }
                .padding(16)
            }
            .background { LibrarySurfaceBackgroundView() }
            .navigationTitle("利用者カード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
#endif

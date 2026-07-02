#if DEBUG
    import PictureBookLendingUI
    import SwiftUI
    
    /// UIカタログ（DEBUGビルド限定）
    ///
    /// 開発中のUIコンポーネントをサンプルデータで一覧表示します。
    /// Phase 2のコンポーネントを実機で確認するための足場で、
    /// issue #40（UIカタログ）の最小実装を兼ねます。
    struct UICatalogContainerView: View {
        private let childId = UUID()
        private let guardianId = UUID()
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    catalogSection("家庭の枠：返却文脈（両方貸出中・1件延滞）") {
                        FamilyLoanSlotsView(
                            slots: [
                                FamilyLoanSlotDisplay(
                                    id: childId, roleLabel: "園児の本", memberName: "いとう さくら",
                                    loan: FamilyLoanSlotLoan(
                                        bookTitle: "ぐりとぐら",
                                        imageURL: "https://picsum.photos/seed/guri/112/144",
                                        dueDateText: "6月20日（土）",
                                        isOverdue: false)),
                                FamilyLoanSlotDisplay(
                                    id: guardianId, roleLabel: "保護者の本", memberName: "伊藤 由美子",
                                    loan: FamilyLoanSlotLoan(
                                        bookTitle: "だいくとおにろく",
                                        imageURL: "https://picsum.photos/seed/oni/112/144",
                                        dueDateText: "6月14日（日）",
                                        isOverdue: true)),
                            ],
                            mode: .returning,
                            onReturn: { _ in },
                            onBorrow: { _ in }
                        )
                        .padding(.vertical, 8)
                    }
                    
                    catalogSection("家庭の枠：貸出文脈（保護者枠が空き）") {
                        FamilyLoanSlotsView(
                            slots: [
                                FamilyLoanSlotDisplay(
                                    id: childId, roleLabel: "園児の本", memberName: "いとう さくら",
                                    loan: FamilyLoanSlotLoan(
                                        bookTitle: "ぐりとぐら",
                                        imageURL: "https://picsum.photos/seed/guri/112/144",
                                        dueDateText: "6月20日（土）",
                                        isOverdue: false)),
                                FamilyLoanSlotDisplay(
                                    id: guardianId, roleLabel: "保護者の本", memberName: "伊藤 由美子",
                                    loan: nil),
                            ],
                            mode: .borrowing,
                            onReturn: { _ in },
                            onBorrow: { _ in }
                        )
                        .padding(.vertical, 8)
                    }
                    
                    catalogSection("家庭の枠：返却文脈（片方のみ貸出中）") {
                        FamilyLoanSlotsView(
                            slots: [
                                FamilyLoanSlotDisplay(
                                    id: childId, roleLabel: "園児の本", memberName: "あおき はると",
                                    loan: FamilyLoanSlotLoan(
                                        bookTitle: "はらぺこあおむし",
                                        imageURL: "https://picsum.photos/seed/aomushi/112/144",
                                        dueDateText: "6月20日（土）",
                                        isOverdue: false)),
                                FamilyLoanSlotDisplay(
                                    id: guardianId, roleLabel: "保護者の本", memberName: "青木 恵",
                                    loan: nil),
                            ],
                            mode: .returning,
                            onReturn: { _ in },
                            onBorrow: { _ in }
                        )
                        .padding(.vertical, 8)
                    }
                }
                .padding(24)
            }
            .background(.background)
            .navigationTitle("UIカタログ（開発用）")
        }
        
        /// 見出し付きのカタログ区画
        private func catalogSection<Content: View>(
            _ title: String, @ViewBuilder content: () -> Content
        ) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                content()
            }
        }
    }
    
    #Preview {
        NavigationStack {
            UICatalogContainerView()
        }
    }
#endif

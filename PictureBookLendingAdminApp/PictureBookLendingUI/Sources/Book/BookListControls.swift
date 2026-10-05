import PictureBookLendingDomain
import SwiftUI

/// 表示設定は常に右側のMenuにまとめ、実幅に応じてかな選択だけを畳む。
struct BookListControls: View {
    @Binding var selectedKana: KanaGroup?
    @Binding var sort: BookSortType
    @Binding var mode: BookDisplayMode
    let kanaOptions: [KanaGroup]
    
    private enum Layout {
        static let groupSpacing: CGFloat = 24
        static let menuSpacing: CGFloat = 12
    }
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Layout.groupSpacing) {
                kanaChips.fixedSize()
                Spacer(minLength: 0)
                displayMenus
            }
            
            HStack(spacing: Layout.groupSpacing) {
                kanaMenu.fixedSize()
                Spacer(minLength: 0)
                displayMenus
            }
            
            VStack(alignment: .leading, spacing: Layout.groupSpacing) {
                kanaMenu
                displayMenus
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }

    private var displayMenus: some View {
        BookDisplayMenus(sort: $sort, mode: $mode, spacing: Layout.menuSpacing)
    }
    
    private var kanaChips: some View {
        HStack {
            ForEach(kanaOptions, id: \.self) { group in
                Button {
                    selectedKana = selectedKana == group ? nil : group
                } label: {
                    Text(group.displayName)
                        // 標準の外観を保ち、1文字のラベルにも押しやすい余白を確保する。
                        .frame(minWidth: 24, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .tint(selectedKana == group ? .accentColor : .secondary)
                .accessibilityAddTraits(selectedKana == group ? .isSelected : [])
            }
        }
    }
    
    private var kanaMenu: some View {
        Menu {
            Button("絞り込みを解除", systemImage: "xmark.circle") {
                selectedKana = nil
            }
            .disabled(selectedKana == nil)
            Divider()
            ForEach(kanaOptions, id: \.self) { group in
                Button {
                    selectedKana = selectedKana == group ? nil : group
                } label: {
                    if selectedKana == group {
                        Label(group.displayName, systemImage: "checkmark")
                    } else {
                        Text(group.displayName)
                    }
                }
            }
        } label: {
            Label(selectedKana?.displayName ?? "五十音", systemImage: "line.3.horizontal.decrease")
        }
        .accessibilityLabel("五十音の絞り込み")
        .accessibilityValue(selectedKana?.displayName ?? "すべて")
        .accessibilityIdentifier("book.kana.menu")
    }
}

/// 現在の一覧だけに作用する並び順・表示形式の操作
public struct BookDisplayMenus: View {
    @Binding private var sort: BookSortType
    @Binding private var mode: BookDisplayMode
    private let spacing: CGFloat

    private enum Layout {
        static let minimumControlSize: CGFloat = 44
    }

    public init(sort: Binding<BookSortType>, mode: Binding<BookDisplayMode>, spacing: CGFloat = 0) {
        self._sort = sort
        self._mode = mode
        self.spacing = spacing
    }

    public var body: some View {
        // ツールバーでは追加余白をなくし、本文内では指定した間隔を使う。
        HStack(spacing: spacing) {
            Menu {
                sortPicker
            } label: {
                Image(systemName: sort.iconName)
                    .frame(minWidth: Layout.minimumControlSize, minHeight: Layout.minimumControlSize)
            }
            .accessibilityLabel("並び順")
            .accessibilityValue(sort.displayName)
            .accessibilityIdentifier("book.sort.menu")

            Menu {
                modePicker
            } label: {
                Image(systemName: mode.iconName)
                    .frame(minWidth: Layout.minimumControlSize, minHeight: Layout.minimumControlSize)
            }
            .accessibilityLabel("表示形式")
            .accessibilityValue(mode.displayName)
            .accessibilityIdentifier("book.mode.menu")
        }
        .fixedSize()
    }
    
    private var sortPicker: some View {
        Picker("並び順", selection: $sort) {
            ForEach(BookSortType.allCases) { value in
                Text(value.displayName).tag(value)
            }
        }
        .accessibilityIdentifier("book.sort.picker")
    }
    
    private var modePicker: some View {
        Picker("表示形式", selection: $mode) {
            ForEach(BookDisplayMode.allCases) { value in
                Label(value.displayName, systemImage: value.iconName).tag(value)
            }
        }
        .labelStyle(.iconOnly)
        .accessibilityIdentifier("book.mode.picker")
    }
}

#Preview("かなチップ・幅と文字サイズ", traits: .fixedLayout(width: 1024, height: 660)) {
    @Previewable @State var selectedKana: KanaGroup? = .ka
    @Previewable @State var sort: BookSortType = .title
    @Previewable @State var mode: BookDisplayMode = .shelf

    VStack(alignment: .leading, spacing: 24) {
        Text(verbatim: "1024pt：全チップ")
        BookListControls(
            selectedKana: $selectedKana, sort: $sort, mode: $mode,
            kanaOptions: KanaGroup.allCases)
        Text(verbatim: "744pt：かな選択の収まり")
        BookListControls(
            selectedKana: $selectedKana, sort: $sort, mode: $mode,
            kanaOptions: KanaGroup.allCases
        )
        .frame(width: 744)
        Text(verbatim: "375pt：かな選択の収まり")
        BookListControls(
            selectedKana: $selectedKana, sort: $sort, mode: $mode,
            kanaOptions: KanaGroup.allCases
        )
        .frame(width: 375)
        Text(verbatim: "1024pt・AX3：文字の拡大")
        BookListControls(
            selectedKana: $selectedKana, sort: $sort, mode: $mode,
            kanaOptions: KanaGroup.allCases
        )
        .dynamicTypeSize(.accessibility3)
    }
    .padding(.vertical, 24)
    .background(Color(.systemBackground))
    .preferredColorScheme(.light)
}

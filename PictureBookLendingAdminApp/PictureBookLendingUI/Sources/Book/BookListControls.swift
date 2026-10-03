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
        static let minimumControlSize: CGFloat = 44
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
                displayMenus.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }
    
    private var displayMenus: some View {
        HStack(spacing: Layout.menuSpacing) {
            Menu {
                sortPicker
            } label: {
                Image(systemName: sort.iconName)
                    .frame(
                        minWidth: Layout.minimumControlSize, minHeight: Layout.minimumControlSize)
            }
            .accessibilityLabel("並び順")
            .accessibilityValue(sort.displayName)
            .accessibilityIdentifier("book.sort.menu")
            
            Menu {
                modePicker
            } label: {
                Image(systemName: mode.iconName)
                    .frame(
                        minWidth: Layout.minimumControlSize, minHeight: Layout.minimumControlSize)
            }
            .accessibilityLabel("表示形式")
            .accessibilityValue(mode.displayName)
            .accessibilityIdentifier("book.mode.menu")
        }
        .fixedSize()
    }
    
    private var kanaChips: some View {
        HStack {
            ForEach(kanaOptions, id: \.self) { group in
                Button(group.displayName) {
                    selectedKana = selectedKana == group ? nil : group
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

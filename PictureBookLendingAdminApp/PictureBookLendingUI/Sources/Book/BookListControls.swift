import PictureBookLendingDomain
import SwiftUI

/// 必要な実幅で操作の畳み方だけを切り替える。狭幅でもかな選択・解除を残す。
struct BookListControls: View {
    @Binding var selectedKana: KanaGroup?
    @Binding var sort: BookSortType
    @Binding var mode: BookDisplayMode
    let kanaOptions: [KanaGroup]
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                kanaChips
                Spacer(minLength: 16)
                sortPicker.pickerStyle(.segmented).fixedSize()
                modePicker.pickerStyle(.segmented).fixedSize()
            }
            .fixedSize(horizontal: true, vertical: false)
            
            HStack(spacing: 12) {
                kanaMenu
                Spacer(minLength: 8)
                Menu {
                    sortPicker
                } label: {
                    Image(systemName: sort.iconName)
                }
                .accessibilityLabel("並び順")
                .accessibilityValue(sort.displayName)
                .accessibilityIdentifier("book.sort.menu")
                Menu {
                    modePicker
                } label: {
                    Image(systemName: mode.iconName)
                }
                .accessibilityLabel("表示形式")
                .accessibilityValue(mode.displayName)
                .accessibilityIdentifier("book.mode.menu")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
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

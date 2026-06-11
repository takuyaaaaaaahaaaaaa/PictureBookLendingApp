import SwiftUI

/// 端末初期化選択ダイアログ
public struct DeviceResetDialog: View {
    @Binding var isPresented: Bool
    @Binding var selectedOptions: DeviceResetOptions
    let onConfirm: (DeviceResetOptions) -> Void
    
    public init(
        isPresented: Binding<Bool>,
        selectedOptions: Binding<DeviceResetOptions>,
        onConfirm: @escaping (DeviceResetOptions) -> Void
    ) {
        self._isPresented = isPresented
        self._selectedOptions = selectedOptions
        self.onConfirm = onConfirm
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 警告メッセージ
                warningSection
                
                // 削除オプション選択
                optionsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("端末初期化")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("削除実行") {
                        onConfirm(selectedOptions)
                        isPresented = false
                    }
                    .foregroundStyle(.red)
                    .disabled(!selectedOptions.hasAnySelection)
                }
            }
        }
    }
    
    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("警告")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            
            Text("選択したデータは完全に削除され、復元できません。操作を実行する前に、必要なデータのバックアップを取ってください。")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.leading, 24)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("削除するデータを選択してください")
                .font(.headline)
            
            CheckboxRow(
                isSelected: $selectedOptions.deleteUsers,
                title: "利用者データ",
                subtitle: "全ての利用者情報を削除"
            )
            
            CheckboxRow(
                isSelected: $selectedOptions.deleteBooks,
                title: "絵本データ",
                subtitle: "全ての絵本情報を削除"
            )
            
            CheckboxRow(
                isSelected: $selectedOptions.deleteLoanRecords,
                title: "貸出記録",
                subtitle: "全ての貸出・返却記録を削除"
            )
        }
    }
}

/// チェックボックス付きの行
private struct CheckboxRow: View {
    @Binding var isSelected: Bool
    let title: String
    let subtitle: String
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

/// 端末初期化のオプション
public struct DeviceResetOptions {
    public var deleteUsers: Bool = false
    public var deleteBooks: Bool = false
    public var deleteLoanRecords: Bool = false
    
    public var hasAnySelection: Bool {
        deleteUsers || deleteBooks || deleteLoanRecords
    }
    
    public init() {}
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var options = DeviceResetOptions()
    
    DeviceResetDialog(
        isPresented: $isPresented,
        selectedOptions: $options,
        onConfirm: { selectedOptions in
            print("削除実行: \(selectedOptions)")
        }
    )
}

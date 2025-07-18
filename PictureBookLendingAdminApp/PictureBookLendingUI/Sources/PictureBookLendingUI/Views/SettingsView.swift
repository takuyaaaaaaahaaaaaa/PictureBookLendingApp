import SwiftUI

/// 設定画面のPresentation View
///
/// 管理者用の設定メニューを表示します。
/// NavigationStackや画面遷移はContainer Viewに委譲します。
public struct SettingsView: View {
    let onSelectClassGroup: () -> Void
    let onSelectUser: () -> Void
    let onSelectBook: () -> Void
    let onSelectLoanSettings: () -> Void
    
    public init(
        onSelectClassGroup: @escaping () -> Void,
        onSelectUser: @escaping () -> Void,
        onSelectBook: @escaping () -> Void,
        onSelectLoanSettings: @escaping () -> Void
    ) {
        self.onSelectClassGroup = onSelectClassGroup
        self.onSelectUser = onSelectUser
        self.onSelectBook = onSelectBook
        self.onSelectLoanSettings = onSelectLoanSettings
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Button(action: onSelectClassGroup) {
                HStack {
                    Image(systemName: "person.3")
                        .font(.title2)
                        .frame(width: 30)
                    Text("組管理")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: onSelectUser) {
                HStack {
                    Image(systemName: "person.2")
                        .font(.title2)
                        .frame(width: 30)
                    Text("利用者管理")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: onSelectBook) {
                HStack {
                    Image(systemName: "book")
                        .font(.title2)
                        .frame(width: 30)
                    Text("絵本管理")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: onSelectLoanSettings) {
                HStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .frame(width: 30)
                    Text("貸出設定")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            onSelectClassGroup: {},
            onSelectUser: {},
            onSelectBook: {},
            onSelectLoanSettings: {}
        )
        .navigationTitle("設定")
    }
}

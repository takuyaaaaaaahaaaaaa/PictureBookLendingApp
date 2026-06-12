import PictureBookLendingDomain
import SwiftUI

/// 絵本自動入力ボタンのPresentation View
///
/// 純粋なUI表示のみを担当し、ビジネスロジックはContainer側に委譲します。
public struct BookAutoFillButton: View {
    /// 検索中フラグ
    let isSearching: Bool
    /// 検索エラーメッセージ
    let searchError: String?
    /// 検索実行アクション
    let onSearch: () -> Void
    
    public init(
        isSearching: Bool,
        searchError: String?,
        onSearch: @escaping () -> Void
    ) {
        self.isSearching = isSearching
        self.searchError = searchError
        self.onSearch = onSearch
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Button("自動入力") {
                onSearch()
            }
            .buttonStyle(.bordered)
            .disabled(isSearching)
            
            if let searchError = searchError {
                Text(searchError)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BookAutoFillButton(
            isSearching: false,
            searchError: nil,
            onSearch: {
                print("Search triggered")
            }
        )
        
        BookAutoFillButton(
            isSearching: true,
            searchError: nil,
            onSearch: {}
        )
        
        BookAutoFillButton(
            isSearching: false,
            searchError: "検索に失敗しました",
            onSearch: {}
        )
    }
    .padding()
}

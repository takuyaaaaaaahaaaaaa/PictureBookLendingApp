import SwiftUI

/// 検索・フィルタバーの共通UIコンポーネント
///
/// iPad横向きでの利用に最適化された検索・フィルタ機能を提供します。
/// 絵本一覧・園児一覧などで統一されたUIを実現します。
struct SearchAndFilterBarView<FilterType: RawRepresentable & CaseIterable & Hashable>: View where FilterType.RawValue == String {
    @Binding var searchText: String
    let searchPlaceholder: String
    @Binding var selectedFilter: FilterType
    let filterOptions: [FilterType]
    
    var body: some View {
        VStack(spacing: 12) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(searchPlaceholder, text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !searchText.isEmpty {
                    Button("クリア") {
                        searchText = ""
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            // フィルタボタン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Button(filter.rawValue) {
                            selectedFilter = filter
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(selectedFilter == filter ? .blue : .gray)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    enum SampleFilter: String, CaseIterable {
        case all = "すべて"
        case available = "利用可能"
        case unavailable = "利用不可"
    }
    
    @State var searchText = ""
    @State var selectedFilter = SampleFilter.all
    
    return SearchAndFilterBarView(
        searchText: $searchText,
        searchPlaceholder: "検索...",
        selectedFilter: $selectedFilter,
        filterOptions: SampleFilter.allCases
    )
}
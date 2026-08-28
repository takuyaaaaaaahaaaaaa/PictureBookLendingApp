import PictureBookLendingDomain
import SwiftUI

/// 書籍検索データ提供元のクレジット表記を表示するPresentation View
///
/// 楽天ウェブサービスなど、規約でクレジット表記が義務付けられている
/// データ源を使用する場合に、指定の文言とリンクを控えめに表示します。
public struct SearchProviderAttributionView: View {
    let attribution: SearchProviderAttribution
    
    public init(attribution: SearchProviderAttribution) {
        self.attribution = attribution
    }
    
    public var body: some View {
        Group {
            if let url = attribution.url {
                Link(attribution.text, destination: url)
            } else {
                Text(attribution.text)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    SearchProviderAttributionView(attribution: .rakuten)
        .padding()
}

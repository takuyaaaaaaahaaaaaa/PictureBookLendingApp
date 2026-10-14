import SwiftUI
#if os(iOS)
    import UIKit
#endif

extension View {
    /// 貸出・返却の検索コントロールを、一覧の上端に配置する。
    public func lendingControlsBar<BarContent: View>(
        @ViewBuilder content: () -> BarContent
    ) -> some View {
        modifier(LendingControlsBar(content: content()))
    }
}

struct LendingControlsBar<BarContent: View>: ViewModifier {
    let content: BarContent

    private var needsLargeTitleWorkaround: Bool {
        #if os(iOS)
            if #available(iOS 27, *) { return false }
            if #available(iOS 26, *) {
                return UIDevice.current.userInterfaceIdiom == .phone
            }
        #endif
        return false
    }

    @ViewBuilder
    func body(content base: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            // iOS 26のiPhoneではsafeAreaBarの端効果が大タイトルをぼかす。
            // 27.0 (24A434)では非再現。iPadと新OSは標準のバーを維持する。
            base
                .safeAreaBar(edge: .top, spacing: 0) {
                    if !needsLargeTitleWorkaround { content }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    if needsLargeTitleWorkaround {
                        content
                            .background {
                                // 一覧が検索欄の背後に透けないよう、既存の背景を使う。
                                LibrarySurfaceBackgroundView()
                            }
                    }
                }
        } else {
            base.safeAreaInset(edge: .top, spacing: 0) { content }
        }
    }
}

import Foundation
import PictureBookLendingUI
import SwiftUI

/// 不具合・要望報告フォームのコンテナビュー
struct FeedbackFormContainerView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: FeedbackReportType = .bug
    @State private var detailText = ""
    @State private var alertState = AlertState()
    
    /// キャンセル操作をシートのdismissに変換するBinding
    private var isPresented: Binding<Bool> {
        Binding(get: { true }, set: { newValue in if !newValue { dismiss() } })
    }
    
    var body: some View {
        FeedbackFormView(
            isPresented: isPresented,
            selectedType: $selectedType,
            detailText: $detailText,
            onSend: handleSend
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func handleSend() {
        guard
            let url = FeedbackReportMailComposer.makeMailURL(
                type: selectedType,
                detailText: detailText,
                appVersion: Self.appVersion,
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString
            )
        else {
            alertState = .error(
                "報告の送信に失敗しました",
                message: "入力内容に不正な文字が含まれている可能性があります"
            )
            return
        }
        
        openURL(url) { accepted in
            if accepted {
                dismiss()
            } else {
                alertState = .error(
                    "メールアプリを開けませんでした",
                    message: "お手数ですが \(FeedbackReportMailComposer.recipientEmail) 宛にご連絡ください"
                )
            }
        }
    }
    
    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
        return "\(version) (\(build))"
    }
}

#Preview {
    FeedbackFormContainerView()
}

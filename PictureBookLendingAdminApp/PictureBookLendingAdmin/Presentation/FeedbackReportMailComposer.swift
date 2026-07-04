import Foundation
import PictureBookLendingUI

/// 不具合・要望報告メールの宛先・件名・本文を組み立てる
enum FeedbackReportMailComposer {
    static let recipientEmail = "majikani2011@gmail.com"
    
    /// 報告メールを起こすための mailto URL を生成する
    static func makeMailURL(
        type: FeedbackReportType,
        detailText: String,
        appVersion: String,
        osVersion: String
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipientEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: makeSubject(type: type)),
            URLQueryItem(
                name: "body",
                value: makeBody(
                    detailText: detailText, appVersion: appVersion, osVersion: osVersion)
            ),
        ]
        return components.url
    }
    
    private static func makeSubject(type: FeedbackReportType) -> String {
        "【\(type.displayName)】絵本貸出アプリ"
    }
    
    private static func makeBody(detailText: String, appVersion: String, osVersion: String)
        -> String
    {
        """
        \(detailText)

        ---
        アプリバージョン: \(appVersion)
        OSバージョン: \(osVersion)
        """
    }
}

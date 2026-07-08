import Foundation

/// 不具合・要望報告用Googleフォームへのリンク
///
/// 「お立場」設問を回答者に応じて事前入力（prefilled link）することで、
/// 職員・保護者の回答を1つのフォーム・1つの集計シートに集約する。
enum FeedbackFormLinks {
    static let staff = URL(
        string:
            "https://docs.google.com/forms/d/e/1FAIpQLSdPMzSPr9g9sMVlcZECImG8XfKE5yLZXInnu3GDF4km4s90_w/viewform?usp=pp_url&entry.1414470172=%E5%85%88%E7%94%9F%E3%83%BB%E8%81%B7%E5%93%A1"
    )!
    
    static let parent = URL(
        string:
            "https://docs.google.com/forms/d/e/1FAIpQLSdPMzSPr9g9sMVlcZECImG8XfKE5yLZXInnu3GDF4km4s90_w/viewform?usp=pp_url&entry.1414470172=%E4%BF%9D%E8%AD%B7%E8%80%85"
    )!
}

//
//  PictureBookLendingAdminWidget.swift
//  PictureBookLendingAdminWidget
//
//  Created by takuya_tominaga on 9/3/25.
//

import SwiftUI
import WidgetKit

/// 絵本管理アプリのWidget
struct PictureBookLendingAdminWidget: Widget {
    let kind: String = "絵本管理アプリ表示ボタン"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PictureBookLendingAdminWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("絵本管理アプリ")
        .description("このボタンを押すことでロック画面から絵本管理アプリが開けます。")
        .supportedFamilies([
            // ロック画面用
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

/// ウィジット表示情報
struct StatusEntry: TimelineEntry {
    /// ウィジットの更新日時
    var date: Date
}

struct Provider: TimelineProvider {
    typealias Entry = StatusEntry
    
    /// 貸出数
    var loanCount: Int?
    
    /// ウィジットギャラリーでの表示
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry = StatusEntry(date: date)
        completion(entry)
    }
    
    /// 更新タイミング
    func getTimeline(
        in context: Context, completion: @escaping @Sendable (Timeline<StatusEntry>) -> Void
    ) {
        let date = Date()
        let entry = StatusEntry(date: date)
        // 15分後に更新
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        return completion(timeline)
    }
    
    /// プレースホルダー
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: Date())
    }
}

/// ウィジットView
struct PictureBookLendingAdminWidgetEntryView: View {
    /// ウィジットサイズ
    @Environment(\.widgetFamily) var family: WidgetFamily
    /// 表示情報
    var entry: Provider.Entry
    
    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryRectangular:
                accessoryRectangularView
            default:
                systemDefaultView
            }
        }
        .foregroundStyle(.white)
        .containerBackground(.orange, for: .widget)
    }
    
    /// アプリ名を取得
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "絵本管理アプリ"
    }
    
    private var accessoryCircularView: some View {
        Image(systemName: "book.fill")
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(.blue)
            .containerBackground(.orange, for: .widget)
    }
    
    private var accessoryRectangularView: some View {
        VStack {
            Text(appName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("をタップして開く")
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
    
    private var systemDefaultView: some View {
        VStack {
            Image(systemName: "book.fill")
                .font(.system(size: 40, weight: .medium))
            
            Text(appName)
                .font(.headline)
                .fontWeight(.semibold)
            Text("タップして開く")
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
    
}

#Preview(as: .systemMedium) {
    PictureBookLendingAdminWidget()
} timeline: {
    StatusEntry(date: Date())
}

#Preview(as: .accessoryRectangular) {
    PictureBookLendingAdminWidget()
} timeline: {
    StatusEntry(date: Date())
}

#Preview(as: .accessoryCircular) {
    PictureBookLendingAdminWidget()
} timeline: {
    StatusEntry(date: Date())
}

#Preview(as: .accessoryInline) {
    PictureBookLendingAdminWidget()
} timeline: {
    StatusEntry(date: Date())
}

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
        //.supportedFamilies(supportedFamilies)
    }
    
    //    private var supportedFamilies: [WidgetFamily] {
    //        [
    //            .systemExtraLarge,
    //            .systemLarge,
    //            .systemMedium,
    //            .systemSmall,
    //        ]
    //    }
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
        switch family {
        case .systemLarge:
            systemLargeView
        case .systemExtraLarge:
            systemExtraLargeView
        default:
            systemDefaultView
        }
    }
    
    /// アプリ名を取得
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "絵本管理アプリ"
    }
    
    private var systemDefaultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.blue)
            
            Text(appName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("タップして開く")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.quaternary, for: .widget)
    }
    
    private var systemLargeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(.blue)
            
            Text(appName)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("タップして開く")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.quaternary, for: .widget)
    }
    
    private var systemExtraLargeView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("絵本の貸出を管理するアプリ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                Text("タップしてアプリを開く")
                Spacer()
            }
            .font(.system(size: 50, weight: .medium))
            .foregroundStyle(.secondary)
            
            Spacer()
            
        }
        .padding()
        .containerBackground(.fill.quaternary, for: .widget)
    }
}

#Preview(as: .systemExtraLarge) {
    PictureBookLendingAdminWidget()
} timeline: {
    StatusEntry(date: Date())
}

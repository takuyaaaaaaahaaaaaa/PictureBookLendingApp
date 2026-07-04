import SwiftUI

/// 報告種別
public enum FeedbackReportType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case bug
    case request
    case other
    
    public var id: String { rawValue }
    
    /// 表示名
    public var displayName: String {
        switch self {
        case .bug: "不具合報告"
        case .request: "ご要望"
        case .other: "その他"
        }
    }
}

/// 不具合・要望報告フォームのPresentation View
public struct FeedbackFormView: View {
    @Binding var isPresented: Bool
    @Binding var selectedType: FeedbackReportType
    @Binding var detailText: String
    let onSend: () -> Void
    
    public init(
        isPresented: Binding<Bool>,
        selectedType: Binding<FeedbackReportType>,
        detailText: Binding<String>,
        onSend: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self._selectedType = selectedType
        self._detailText = detailText
        self.onSend = onSend
    }
    
    private var isDetailEmpty: Bool {
        detailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("種別") {
                    Picker("種別", selection: $selectedType) {
                        ForEach(FeedbackReportType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                Section("内容") {
                    ZStack(alignment: .topLeading) {
                        if detailText.isEmpty {
                            Text("不具合の内容や、改善してほしい点を自由にご記入ください")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $detailText)
                            .frame(minHeight: 200)
                    }
                }
                
                Section {
                    Text("送信するとメールアプリが開き、開発者宛の下書きが作成されます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("不具合・ご要望を報告")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        onSend()
                    }
                    .disabled(isDetailEmpty)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var selectedType = FeedbackReportType.bug
    @Previewable @State var detailText = ""
    
    FeedbackFormView(
        isPresented: $isPresented,
        selectedType: $selectedType,
        detailText: $detailText,
        onSend: {}
    )
}

import PictureBookLendingDomain
import SwiftUI

/// 組追加・編集フォームのPresentation View
///
/// 組情報の入力フォームを表示します。
/// バリデーションやデータ保存はContainer Viewに委譲します。
public struct ClassGroupFormView: View {
    let mode: ClassGroupFormMode
    @Binding var name: String
    @Binding var ageGroup: Int
    @Binding var year: Int
    
    public init(
        mode: ClassGroupFormMode,
        name: Binding<String>,
        ageGroup: Binding<Int>,
        year: Binding<Int>
    ) {
        self.mode = mode
        self._name = name
        self._ageGroup = ageGroup
        self._year = year
    }
    
    public var body: some View {
        Form {
            Section("組情報") {
                TextField("組名", text: $name)
                
                Picker("年齢", selection: $ageGroup) {
                    ForEach(0..<6) { age in
                        Text("\(age)歳児").tag(age)
                    }
                }
                
                Picker("年度", selection: $year) {
                    ForEach(2020...2050, id: \.self) { year in
                        Text("\(year,format:.number.grouping(.never))年度").tag(year)
                    }
                }
            }
        }
    }
}

/// 組フォームのモード
public enum ClassGroupFormMode {
    case add
    case edit(ClassGroup)
    
    public var title: String {
        switch self {
        case .add:
            return "組を追加"
        case .edit:
            return "組を編集"
        }
    }
}

#Preview("追加モード") {
    NavigationStack {
        ClassGroupFormView(
            mode: .add,
            name: .constant(""),
            ageGroup: .constant(3),
            year: .constant(2024)
        )
        .navigationTitle("組を追加")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("編集モード") {
    NavigationStack {
        ClassGroupFormView(
            mode: .edit(ClassGroup(name: "ひまわり組", ageGroup: 3, year: 2024)),
            name: .constant("ひまわり組"),
            ageGroup: .constant(3),
            year: .constant(2024)
        )
        .navigationTitle("組を編集")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

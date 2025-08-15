import PictureBookLendingDomain
import SwiftUI

/// UI用のシンプルな利用者種別（Associated Valueなし）
public enum UserTypeForPicker: String, CaseIterable, Codable, Hashable {
    /// 園児
    case child = "child"
    /// 保護者
    case guardian = "guardian"
    
    /// 表示用の日本語名
    public var displayName: String {
        switch self {
        case .child:
            return "園児"
        case .guardian:
            return "保護者"
        }
    }
    
    /// UserTypeに変換（保護者の場合は仮のUUIDを使用）
    public func toUserType(guardianRelatedChildId: UUID? = nil) -> UserType {
        switch self {
        case .child:
            return .child
        case .guardian:
            return .guardian(relatedChildId: guardianRelatedChildId ?? UUID())
        }
    }
    
    /// UserTypeから変換
    public static func from(_ userType: UserType) -> UserTypeForPicker {
        switch userType {
        case .child:
            return .child
        case .guardian:
            return .guardian
        }
    }
}

/// 利用者フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserFormView: View {
    let editingUser: User?
    let name: Binding<String>
    let classGroup: Binding<ClassGroup?>
    let classGroups: [ClassGroup]
    let userType: Binding<UserType>
    let userTypeForPicker: Binding<UserTypeForPicker>
    let shouldRegisterGuardians: Binding<Bool>
    let guardianCount: Int
    let availableChildren: [User]
    let selectedChild: Binding<User?>
    
    public init(
        editingUser: User? = nil,
        name: Binding<String>,
        classGroup: Binding<ClassGroup?>,
        classGroups: [ClassGroup],
        userType: Binding<UserType>,
        userTypeForPicker: Binding<UserTypeForPicker>,
        shouldRegisterGuardians: Binding<Bool>,
        guardianCount: Int,
        availableChildren: [User] = [],
        selectedChild: Binding<User?> = .constant(nil)
    ) {
        self.editingUser = editingUser
        self.name = name
        self.classGroup = classGroup
        self.classGroups = classGroups
        self.userType = userType
        self.userTypeForPicker = userTypeForPicker
        self.shouldRegisterGuardians = shouldRegisterGuardians
        self.guardianCount = guardianCount
        self.availableChildren = availableChildren
        self.selectedChild = selectedChild
    }
    
    public var body: some View {
        Form {
            Section(header: Text("利用者情報")) {
                Picker("利用者種別", selection: userTypeForPicker) {
                    ForEach(UserTypeForPicker.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                TextField("名前", text: name)
                Picker("組", selection: classGroup) {
                    Text("組を選択してください").tag(nil as ClassGroup?)
                    ForEach(classGroups) { group in
                        Text(group.name).tag(group as ClassGroup?)
                    }
                }
            }
            
            // 保護者を選択した場合は関連する園児を選択
            if editingUser == nil && userTypeForPicker.wrappedValue == .guardian {
                Section(header: Text("関連する利用者")) {
                    Picker("利用者を選択", selection: selectedChild) {
                        Text("利用者を選択してください").tag(nil as User?)
                        ForEach(availableChildren) { child in
                            Text(child.name).tag(child as User?)
                        }
                    }
                    
                    if selectedChild.wrappedValue != nil {
                        Text("選択した利用者の保護者として登録されます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // 利用者を選択した場合は保護者の同時登録オプション
            if editingUser == nil && userTypeForPicker.wrappedValue == .child {
                Section(header: Text("保護者登録")) {
                    Toggle(
                        "合わせて保護者も利用者登録します。",
                        isOn: shouldRegisterGuardians
                    )
                    
                    if shouldRegisterGuardians.wrappedValue {
                        HStack {
                            Text("登録する保護者数")
                            Spacer()
                            Text("\(guardianCount)人")
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(
                            "保護者名は「\(name.wrappedValue)の保護者1」「\(name.wrappedValue)の保護者2」として自動設定されます"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var userTypeForPicker: UserTypeForPicker = .child
    
    let sampleUser = User(name: "山田太郎", classGroupId: UUID())
    let classGroups = [
        ClassGroup(name: "きく", ageGroup: "1歳児", year: 2025),
        ClassGroup(name: "ひまわり", ageGroup: "2歳児", year: 2025),
    ]
    
    NavigationStack {
        UserFormView(
            editingUser: sampleUser,
            name: .constant("山田太郎"),
            classGroup: .constant(classGroups[1]),
            classGroups: classGroups,
            userType: .constant(.child),
            userTypeForPicker: $userTypeForPicker,
            shouldRegisterGuardians: .constant(true),
            guardianCount: 2,
            availableChildren: [],
            selectedChild: .constant(nil)
        )
        .navigationTitle("利用者情報を編集")
    }
}

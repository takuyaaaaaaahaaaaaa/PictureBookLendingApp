import SwiftUI

/// 登録された実データから進捗を求めるため、途中でアプリを閉じても続きから再開できる。
struct SetupProgress {
    let hasClassGroup: Bool
    let hasUser: Bool
    let hasBook: Bool

    var completedCount: Int {
        [hasClassGroup, hasUser, hasBook].filter { $0 }.count
    }

    var isComplete: Bool {
        hasClassGroup && hasUser && hasBook
    }

    var nextTitle: String {
        if !hasClassGroup { return "組を登録" }
        if !hasUser { return "利用者を登録" }
        if !hasBook { return "図書を登録" }
        return "貸出を始める"
    }

    var nextExplanation: String {
        if !hasClassGroup { return "組を追加すると、次に利用者を登録できます。" }
        if !hasUser { return "利用者を追加すると、次に図書を登録できます。" }
        if !hasBook { return "図書を追加すると、貸出を始められます。" }
        return "準備ができました。データ送信を選んで貸出画面へ進みます。"
    }
}

struct SetupWelcomeView: View {
    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("OnboardingOwl")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .accessibilityHidden(true)
                Text("えほん台帳をはじめましょう")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("最初に3つだけ登録すると、貸出を始められます。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 16) {
                    step(1, "組", "利用者が所属する組を作成")
                    step(2, "利用者", "絵本を借りる人を登録")
                    step(3, "図書", "貸し出す絵本を登録")
                }
                .frame(maxWidth: 400, alignment: .leading)
                Button("設定で準備を始める", action: onStart)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("あとで設定する", action: onSkip)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.brown, in: Circle())
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct SetupProgressView: View {
    let progress: SetupProgress
    let onContinue: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("はじめての準備  \(progress.completedCount)/3")
                .font(.caption.bold())
                .foregroundStyle(.brown)
            Text(progress.nextTitle).font(.headline)
            Text(progress.nextExplanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let onContinue {
                Button(progress.nextTitle, action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}

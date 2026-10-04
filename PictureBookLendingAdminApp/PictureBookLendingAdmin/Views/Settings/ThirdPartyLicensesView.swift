import Foundation
import SwiftUI

struct ThirdPartyLicensesView: View {
    private static let licenses: [ThirdPartyLicense]? = {
        guard let url = Bundle.main.url(forResource: "ThirdPartyLicenses", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ThirdPartyLicense].self, from: data)
    }()

    var body: some View {
        Group {
            if let licenses = Self.licenses {
                List(licenses) { license in
                    NavigationLink {
                        ThirdPartyLicenseDetailView(license: license)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(license.name)
                            Text("\(license.version) · \(license.licenseName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "ライセンス情報を読み込めませんでした",
                    systemImage: "doc.text"
                )
            }
        }
        .navigationTitle("オープンソースライセンス")
    }
}

private struct ThirdPartyLicenseDetailView: View {
    let license: ThirdPartyLicense

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Link("ソースコード", destination: license.sourceURL)
                Text(verbatim: license.licenseText)
                    .font(.system(.footnote, design: .monospaced))
                if let noticesText = license.noticesText {
                    Text("関連する著作権表示")
                        .font(.headline)
                    Text(verbatim: noticesText)
                        .font(.system(.footnote, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .textSelection(.enabled)
        }
        .navigationTitle(license.name)
    }
}

private struct ThirdPartyLicense: Decodable, Identifiable {
    let id: String
    let name: String
    let version: String
    let licenseName: String
    let sourceURL: URL
    let licenseText: String
    let noticesText: String?
}

import Foundation
import SwiftUI

struct ThirdPartyLicensesView: View {
    private static let licenses: [ThirdPartyLicense]? = {
        guard let url = Bundle.main.url(forResource: "ThirdPartyLicenses", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        guard var items = try? JSONDecoder().decode([ThirdPartyLicense].self, from: data) else {
            return nil
        }
        guard
            let licenseURL = Bundle.main.url(forResource: "FastViT-LICENSE", withExtension: "txt"),
            let licenseText = try? String(contentsOf: licenseURL, encoding: .utf8),
            let noticesURL = Bundle.main.url(
                forResource: "FastViT-ACKNOWLEDGEMENTS", withExtension: "txt"),
            let noticesText = try? String(contentsOf: noticesURL, encoding: .utf8),
            let sourceURL = URL(
                string:
                    "https://github.com/apple/ml-fastvit/tree/8af5928238cab99c45f64fc3e4e7b1516b8224ba"
            )
        else { return nil }
        items.append(
            ThirdPartyLicense(
                id: "apple-fastvit-model", name: "Apple FastViT 表紙検索モデル",
                version: "T8 F16 Headless", licenseName: "Apple Software License",
                sourceURL: sourceURL, licenseText: licenseText, noticesText: noticesText
            ))
        return items
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
        .navigationTitle("ライセンス情報")
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

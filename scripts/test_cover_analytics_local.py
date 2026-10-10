#!/usr/bin/env python3
"""Run real telemetry sources/tests without app secrets, Firebase, or a simulator."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1] / 'PictureBookLendingAdminApp'
with tempfile.TemporaryDirectory(prefix='cover-analytics-') as directory:
    package = Path(directory)
    (package / 'Package.swift').write_text('''// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "TelemetryLocal", platforms: [.macOS(.v14)], targets: [
    .target(name: "PictureBookLendingInfrastructure"),
    .target(name: "PictureBookLendingAdmin", dependencies: ["PictureBookLendingInfrastructure"]),
    .testTarget(name: "TelemetryTests", dependencies: ["PictureBookLendingAdmin", "PictureBookLendingInfrastructure"])
])
''')
    def copy(source, destination):
        target = package / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text((root / source).read_text())
    copy('PictureBookLendingInfrastructure/Sources/Analytics/AnalyticsService.swift',
         'Sources/PictureBookLendingInfrastructure/AnalyticsService.swift')
    for name in ['AnalyticsEvent', 'CoverSearchTelemetry', 'TelemetryPrivacyController', 'TelemetryConsentStore']:
        copy(f'PictureBookLendingAdmin/Presentation/Analytics/{name}.swift',
             f'Sources/PictureBookLendingAdmin/{name}.swift')
    (package / 'Sources/PictureBookLendingAdmin/FirebaseStubs.swift').write_text('''
import PictureBookLendingInfrastructure
struct FirebaseAnalyticsService: AnalyticsService {
    func track(name: String, params: [String: AnalyticsParamValue]) {}
}
@MainActor final class FirebaseTelemetryRuntime: TelemetryRuntime {
    func configure() -> Bool { false }
    func setAnalyticsEnabled(_ enabled: Bool) {}
    func resetAnalyticsData() {}
    func sendUnsentReports() {}
}
''')
    for name in ['AnalyticsEventTests', 'CoverSearchTelemetryTests', 'TelemetryConsentTests']:
        copy(f'PictureBookLendingAdminTests/{name}.swift', f'Tests/TelemetryTests/{name}.swift')
    subprocess.run(['swift', 'test', '--package-path', str(package)], check=True)

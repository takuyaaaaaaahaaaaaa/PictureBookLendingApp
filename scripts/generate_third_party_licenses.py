#!/usr/bin/env python3
"""Bundle license texts for the exact Swift Package revisions in Package.resolved."""

import argparse
import json
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RESOLVED = PROJECT_ROOT / "PictureBookLendingAdminApp/PictureBookLendingAdmin.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
OUTPUT = PROJECT_ROOT / "PictureBookLendingAdminApp/PictureBookLendingAdmin/Resources/ThirdPartyLicenses.json"
PACKAGES = {
    "abseil-cpp-binary": ("Abseil C++ Binary", "Apache-2.0"),
    "app-check": ("App Check", "Apache-2.0"),
    "firebase-ios-sdk": ("Firebase Apple SDK", "Apache-2.0"),
    "google-ads-on-device-conversion-ios-sdk": ("Google Ads On-Device Conversion", "Apache-2.0"),
    "googleappmeasurement": ("Google App Measurement", "Apache-2.0"),
    "googledatatransport": ("Google Data Transport", "Apache-2.0"),
    "googleutilities": ("Google Utilities", "Apache-2.0"),
    "grpc-binary": ("gRPC Binary", "Apache-2.0"),
    "gtm-session-fetcher": ("GTM Session Fetcher", "Apache-2.0"),
    "interop-ios-for-google-sdks": ("Interop for Google SDKs", "Apache-2.0"),
    "kingfisher": ("Kingfisher", "MIT"),
    "leveldb": ("LevelDB", "BSD-3-Clause"),
    "nanopb": ("nanopb", "Zlib"),
    "promises": ("Promises", "Apache-2.0"),
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkouts", type=Path, help="Xcode SourcePackages/checkouts directory")
    parser.add_argument("--check", action="store_true", help="fail if the bundled notices are stale")
    args = parser.parse_args()

    pins = json.loads(RESOLVED.read_text())["pins"]
    identities = {pin["identity"] for pin in pins}
    if identities != PACKAGES.keys():
        raise SystemExit(f"Review new or removed packages: {sorted(identities ^ PACKAGES.keys())}")

    licenses = []
    for pin in pins:
        identity = pin["identity"]
        checkout = args.checkouts / identity
        revision = subprocess.check_output(
            ["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True
        ).strip()
        if revision != pin["state"]["revision"]:
            raise SystemExit(f"{identity}: checkout revision does not match Package.resolved")

        license_files = [path for path in checkout.iterdir() if path.name.upper().startswith("LICENSE")]
        if len(license_files) != 1:
            raise SystemExit(f"{identity}: expected one root LICENSE file, found {len(license_files)}")

        name, license_name = PACKAGES[identity]
        entry = {
            "id": identity,
            "name": name,
            "version": pin["state"]["version"],
            "licenseName": license_name,
            "sourceURL": pin["location"],
            "licenseText": license_files[0].read_text(),
        }
        if identity == "firebase-ios-sdk":
            entry["noticesText"] = (checkout / "CoreOnly/NOTICES").read_text()
        licenses.append(entry)

    licenses.sort(key=lambda entry: entry["name"].casefold())
    content = json.dumps(licenses, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text() != content:
            raise SystemExit("ThirdPartyLicenses.json is stale; regenerate it")
        print(f"Verified {len(licenses)} bundled license entries")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(content)
        print(f"Generated {len(licenses)} license entries at {OUTPUT}")


if __name__ == "__main__":
    main()

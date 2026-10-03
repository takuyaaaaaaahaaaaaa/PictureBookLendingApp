#if canImport(UIKit)
    import UIKit
    import XCTest
    
    @testable import PictureBookLendingUI
    
    /// Asset Catalogが実際にパッケージへ組み込まれ、明暗で解決できることを検証する。
    @MainActor
    final class AppColorTests: XCTestCase {
        func testPackagedColorsResolveForBothAppearances() throws {
            let names = [
                "Lent", "LentSurface", "Available", "Overdue", "Returned", "Destructive",
                "CardSurface", "ChipSurface", "OnEmphasis",
            ]
            for name in names {
                let light = try color(name, style: .light)
                let dark = try color(name, style: .dark)
                XCTAssertNotEqual(light, dark, "\(name) needs light and dark appearances")
            }
        }
        
        func testStatusFillTextContrast() throws {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let foreground = try color("OnEmphasis", style: style)
                for name in ["Available", "Overdue", "Returned", "Destructive"] {
                    let background = try color(name, style: style)
                    let values = [luminance(foreground), luminance(background)].sorted()
                    let ratio = (values[1] + 0.05) / (values[0] + 0.05)
                    XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(name), \(style)")
                }
            }
        }
        
        func testLentSurfaceForegroundContrast() throws {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let foreground = try color("Lent", style: style)
                let background = try color("LentSurface", style: style)
                let values = [luminance(foreground), luminance(background)].sorted()
                XCTAssertGreaterThanOrEqual((values[1] + 0.05) / (values[0] + 0.05), 4.5)
            }
        }
        
        private func color(_ name: String, style: UIUserInterfaceStyle) throws -> UIColor {
            let traits = UITraitCollection(userInterfaceStyle: style)
            return try XCTUnwrap(UIColor(named: name, in: .module, compatibleWith: traits))
                .resolvedColor(with: traits)
        }
        
        private func luminance(_ color: UIColor) -> CGFloat {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            func linear(_ channel: CGFloat) -> CGFloat {
                channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
    }
#endif

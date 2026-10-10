import SwiftUI

extension ButtonRole {
    /// Confirm semantics on supported systems; older systems keep the explicit label.
    public static var confirmIfAvailable: ButtonRole? {
        if #available(iOS 26, macOS 26, *) {
            return .confirm
        }
        return nil
    }

    /// Close semantics on supported systems; older systems use no role (nil).
    public static var closeIfAvailable: ButtonRole? {
        if #available(iOS 26, macOS 26, *) {
            return .close
        }
        return nil
    }
}

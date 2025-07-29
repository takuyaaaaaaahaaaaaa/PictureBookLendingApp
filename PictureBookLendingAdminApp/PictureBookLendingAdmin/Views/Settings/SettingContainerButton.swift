//
//  SettingContainerButton.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 7/26/25.
//

import SwiftUI

/// 設定Containerボタン
public struct SettingContainerButton: View {
    @State var isSettingsPresented: Bool = false
    
    public var body: some View {
        Button("設定", systemImage: "gearshape") {
            isSettingsPresented = true
        }
        #if os(macOS)
            .sheet(isPresented: $isSettingsPresented) {
                SettingsContainerView()
            }
        #else
            .fullScreenCover(isPresented: $isSettingsPresented) {
                SettingsContainerView()
            }
        #endif
    }
}

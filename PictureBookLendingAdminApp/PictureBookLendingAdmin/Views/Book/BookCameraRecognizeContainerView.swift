//
//  BookCameraRecognizeContainerView.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/7/25.

//

import SwiftUI
import VisionKit

/// 絵本スキャンContainerView
struct BookScannerContainerView: UIViewControllerRepresentable {
    
    /// 初回作成時のみ実行
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            // スキャン対象
            recognizedDataTypes: [
                .text(languages: ["ja"]),  // 日本語指定
                .barcode(symbologies: [.ean13]),  // 13桁のISBN対応
            ]
        )
        try? dataScannerViewController.startScanning()
        return dataScannerViewController
    }
    
    // Viewの更新タイミングで実行
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }
}

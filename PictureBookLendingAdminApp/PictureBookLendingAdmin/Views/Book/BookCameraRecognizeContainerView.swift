//
//  BookCameraRecognizeContainerView.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/7/25.

//

import SwiftUI
import VisionKit

/// 絵本スキャンContainerView
struct BookScannerContainerView: View {
    @State var ISBNCode: String = ""
    @State var texts: [String] = []
    @State var showAlert: Bool = false
    
    var body: some View {
        BookScannerView(ISBNCode: $ISBNCode, texts: $texts)
            .alert(
                "取得完了", isPresented: $showAlert, actions: {},
                message: {
                    Text("ISBNCode: \(ISBNCode)\ntexts: \(texts.joined())")
                }
            )
            .onChange(of: ISBNCode) {
                if !ISBNCode.isEmpty {
                    showAlert = true
                }
            }
            .onChange(of: texts) {
                if !texts.isEmpty {
                    showAlert = true
                }
            }
    }
    
}

/// 絵本スキャンView
struct BookScannerView: UIViewControllerRepresentable {
    
    /// ISBNコード
    @Binding var ISBNCode: String
    /// テキスト
    @Binding var texts: [String]
    
    /// 初回作成時のみ実行
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            // スキャン対象
            recognizedDataTypes: [
                .text(languages: ["ja"]),  // 日本語指定
                .barcode(symbologies: [.ean13]),  // 13桁のISBN対応
            ],
            isHighlightingEnabled: true  // スキャン時にハイライト
        )
        dataScannerViewController.delegate = context.coordinator
        try? dataScannerViewController.startScanning()
        return dataScannerViewController
    }
    
    // Viewの更新タイミングで実行
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    // MARK: Coordinator関連処理 UIKit→SwiftUI
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: BookScannerView
        
        init(_ bookScannerView: BookScannerView) {
            self.parent = bookScannerView
        }
        
        // スキャナがアイテムの認識を開始すると呼ばれる
        func dataScanner(
            _ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            
            // ISBN番号を取得
            if case .barcode(let barcode) = addedItems.first,
                let payloadStringValue = barcode.payloadStringValue
            {
                parent.ISBNCode = payloadStringValue
                return
            }
            
            // テキストを取得
            let recognizedTexts = addedItems.compactMap { item -> String? in
                if case .text(let text) = item {
                    return text.transcript
                }
                return nil
            }
            if !recognizedTexts.isEmpty {
                parent.texts = recognizedTexts
                return
            }
        }
        
        // スキャナがアイテムの認識を停止した時に呼ばれる
        func dataScanner(
            _ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            parent.ISBNCode = ""
            parent.texts = []
        }
        
    }
    
}

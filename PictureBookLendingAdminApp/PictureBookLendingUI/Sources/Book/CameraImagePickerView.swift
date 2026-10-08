import SwiftUI

#if canImport(UIKit)
    import UIKit
    import AVFoundation
#endif

#if canImport(UIKit)
    /// カメラ撮影用のImagePicker
    /// UIImagePickerControllerをSwiftUIでラップして、カメラからの画像撮影機能を提供します
    public struct CameraImagePickerView: UIViewControllerRepresentable {
        public typealias UIViewControllerType = UIImagePickerController
        
        /// 撮影完了時のコールバック
        public let onImagePicked: (UIImage) -> Void
        /// キャンセル時のコールバック
        public let onCancel: () -> Void
        /// Whether to show the system image editor after capture.
        public let allowsEditing: Bool
        /// Requested camera, used when available on the device.
        public let cameraDevice: UIImagePickerController.CameraDevice
        
        public init(
            onImagePicked: @escaping (UIImage) -> Void,
            onCancel: @escaping () -> Void,
            cameraDevice: UIImagePickerController.CameraDevice = .rear,
            allowsEditing: Bool = true
        ) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
            self.cameraDevice = cameraDevice
            self.allowsEditing = allowsEditing
        }
        
        public func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(cameraDevice) {
                picker.cameraDevice = cameraDevice
            }
            picker.mediaTypes = ["public.image"]
            picker.allowsEditing = allowsEditing
            return picker
        }
        
        public func updateUIViewController(
            _ uiViewController: UIImagePickerController, context: Context
        ) {
            // 更新処理は不要
        }
        
        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        public class Coordinator: NSObject, UIImagePickerControllerDelegate,
            UINavigationControllerDelegate
        {
            let parent: CameraImagePickerView
            
            init(_ parent: CameraImagePickerView) {
                self.parent = parent
            }
            
            public func imagePickerController(
                _ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
            ) {
                if let editedImage = info[.editedImage] as? UIImage {
                    parent.onImagePicked(editedImage)
                } else if let originalImage = info[.originalImage] as? UIImage {
                    parent.onImagePicked(originalImage)
                }
            }
            
            public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.onCancel()
            }
        }
    }
    
    /// カメラ利用可能性チェック用のユーティリティ
    @MainActor
    public enum CameraUtility {
        /// カメラが利用可能かどうかを確認
        public static var isCameraAvailable: Bool {
            UIImagePickerController.isSourceTypeAvailable(.camera)
        }
        
        /// カメラ権限の状態を確認
        public static var cameraAuthorizationStatus: AVAuthorizationStatus {
            AVCaptureDevice.authorizationStatus(for: .video)
        }
        
        /// カメラ権限をリクエスト
        public static func requestCameraPermission(completion: @Sendable @escaping (Bool) -> Void) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        }
    }
#endif

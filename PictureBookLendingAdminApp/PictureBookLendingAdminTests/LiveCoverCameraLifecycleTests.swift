import AVFoundation
import XCTest
@testable import PictureBookLendingAdmin

/// Synthetic session notifications exercise recovery without starting a camera or
/// requesting permission. Physical interruption/recovery still needs device testing.
@MainActor
final class LiveCoverCameraLifecycleTests: XCTestCase {
    func testSessionFailureOffersRetryOnlyOnce() async {
        for event in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification] {
            let center = NotificationCenter()
            let failure = expectation(description: "Session failure reaches the screen")
            let duplicate = expectation(description: "No duplicate failure after stopping")
            duplicate.isInverted = true
            var delivered = false
            let coordinator = LiveCoverCameraView.Coordinator(onFrame: { _ in false }, onFailure: { message in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertTrue(message.contains("もう一度探す"))
                if delivered { duplicate.fulfill() }
                else { delivered = true; failure.fulfill() }
            }, notificationCenter: center)
            center.post(name: event, object: coordinator.session)
            center.post(name: AVCaptureSession.runtimeErrorNotification, object: coordinator.session)
            await fulfillment(of: [failure], timeout: 2)
            center.post(name: AVCaptureSession.wasInterruptedNotification, object: coordinator.session)
            await fulfillment(of: [duplicate], timeout: 0.1)
            withExtendedLifetime(coordinator) {}
        }
    }

    func testStoppedSessionCannotReportLateFailure() async {
        let center = NotificationCenter()
        let failure = expectation(description: "Dismissed session cannot update the screen")
        failure.isInverted = true
        let coordinator = LiveCoverCameraView.Coordinator(onFrame: { _ in false }, onFailure: { _ in
            failure.fulfill()
        }, notificationCenter: center)
        coordinator.stop()
        // Even if observation has not yet been removed on the camera queue, the
        // queued halt precedes this notification's failure handler.
        center.post(name: AVCaptureSession.runtimeErrorNotification, object: coordinator.session)
        await fulfillment(of: [failure], timeout: 0.1)
        withExtendedLifetime(coordinator) {}
    }

    func testOtherCameraSessionDoesNotInterruptCoverSearch() async {
        let center = NotificationCenter()
        let failure = expectation(description: "Notifications are scoped to this session")
        failure.isInverted = true
        let coordinator = LiveCoverCameraView.Coordinator(onFrame: { _ in false }, onFailure: { _ in
            failure.fulfill()
        }, notificationCenter: center)
        let otherSession = AVCaptureSession()
        center.post(name: AVCaptureSession.wasInterruptedNotification, object: otherSession)
        center.post(name: AVCaptureSession.runtimeErrorNotification, object: otherSession)
        await fulfillment(of: [failure], timeout: 0.1)
        coordinator.stop()
    }
}

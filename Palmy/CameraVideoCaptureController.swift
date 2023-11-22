import OSLog
import WebRTC

class CameraVideoCaptureController: VideoCaptureController {
    var capturer: RTCCameraVideoCapturer

    init(capturer: RTCCameraVideoCapturer) {
        self.capturer = capturer
    }

    func startCapture() {
        guard let frontCamera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }) else {
            Logger.general.warning("This device doesn't have front camera")

            return
        }

        let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).max { firstFormat, secondFormat in
            let firstWidth = CMVideoFormatDescriptionGetDimensions(firstFormat.formatDescription).width
            let secondWidth = CMVideoFormatDescriptionGetDimensions(secondFormat.formatDescription).width

            return firstWidth < secondWidth
        }!

        let frameRateRange = format.videoSupportedFrameRateRanges.max { firstRange, secondRange in
            return firstRange.maxFrameRate < secondRange.maxFrameRate
        }!

        capturer.startCapture(with: frontCamera, format: format, fps: Int(frameRateRange.maxFrameRate))
    }

    func stopCapture() {
        capturer.stopCapture()
    }
}

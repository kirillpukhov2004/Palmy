import WebRTC
import OSLog

class FileVideoCaptureController: VideoCaptureController {
    var capturer: RTCFileVideoCapturer

    init(capturer: RTCFileVideoCapturer) {
        self.capturer = capturer
    }

    func startCapture() {
        capturer.startCapturing(fromFileNamed: "foreman.mp4") { error in
            Logger.general.error("\(error.localizedDescription)")
        }
    }

    func stopCapture() {
        capturer.stopCapture()
    }
}

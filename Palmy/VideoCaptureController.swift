import WebRTC

protocol VideoCaptureController {
    associatedtype VideoCapturerType: RTCVideoCapturer

    var capturer: VideoCapturerType { get }

    func startCapture()

    func stopCapture()
}

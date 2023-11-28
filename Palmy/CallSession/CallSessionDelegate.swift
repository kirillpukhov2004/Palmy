import WebRTC

protocol CallSessionDelegate: AnyObject {
    func callSession(_ callSession: CallSession, didChange connectionState: CallSessionConnectionState)

    func callSession(_ callSession: CallSession, didStartCameraCapturing captureSession: AVCaptureSession)
    func callSessionDidStopCameraCapturing(_ callSession: CallSession)

    func callSession(_ callSession: CallSession, didStartRemoteVideoCapturing videoTrack: RTCVideoTrack)
    func callSessionDidStopRemoteVideoCapturing(_ callSession: CallSession)
}

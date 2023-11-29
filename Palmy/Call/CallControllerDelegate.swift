import WebRTC

protocol CallControllerDelegate: AnyObject {
    func callController(_ callController: CallController, didChange connectionState: CallControllerConnectionState)

    func callController(_ callController: CallController, didStartCameraCapturing captureSession: AVCaptureSession)
    func callControllerDidStopCameraCapturing(_ callSession: CallController)

    func callController(_ callController: CallController, didStartRemoteVideoCapturing videoTrack: RTCVideoTrack)
    func callControllerDidStopRemoteVideoCapturing(_ callSession: CallController)
}

import WebRTC

protocol SignalingServerSessionDelegate: AnyObject {
    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteSessionDescription: RTCSessionDescription)

    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteIceCadidate: RTCIceCandidate)

    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieveRemoved remoteIceCandidate: RTCIceCandidate)
}

extension SignalingServerSessionDelegate {
    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteSessionDescription: RTCSessionDescription) {}

    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteIceCadidate: RTCIceCandidate) {}

    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieveRemoved remoteIceCandidate: RTCIceCandidate) {}
}

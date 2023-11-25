import WebRTC

protocol WebRTCSessionDelegate: AnyObject {
    func webRTCSession(_ webRTCSession: WebRTCSession, didGenerate iceCandidate: RTCIceCandidate)

    func webRTCSession(_ webRTCSession: WebRTCSession, didRemove iceCandidates: [RTCIceCandidate])
}

extension WebRTCSessionDelegate {
    func webRTCSession(_ webRTCSession: WebRTCSession, didGenerate iceCandidate: RTCIceCandidate) {}

    func webRTCSession(_ webRTCSession: WebRTCSession, didRemove iceCandidates: [RTCIceCandidate]) {}
}

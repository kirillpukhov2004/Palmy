import Combine
import WebRTC

class PeerConnectionDelegate: NSObject {
    let didSignalingStateChanged = PassthroughSubject<RTCSignalingState, Never>()
    let didAddMediaStream = PassthroughSubject<RTCMediaStream, Never>()
    let didRemoveMediaStream = PassthroughSubject<RTCMediaStream, Never>()
    let shouldNegotiate = PassthroughSubject<Void, Never>()
    let didIceConnectionStateChanged = PassthroughSubject<RTCIceConnectionState, Never>()
    let didIceGatheringStateChanged = PassthroughSubject<RTCIceGatheringState, Never>()
    let didGenerateIceCandidate = PassthroughSubject<RTCIceCandidate, Never>()
    let didRemoveIceCandidates = PassthroughSubject<[RTCIceCandidate], Never>()
    let didOpenDataChannel = PassthroughSubject<RTCDataChannel, Never>()
}

extension PeerConnectionDelegate: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        didSignalingStateChanged.send(stateChanged)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        didAddMediaStream.send(stream)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        didRemoveMediaStream.send(stream)
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        shouldNegotiate.send()
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        didIceConnectionStateChanged.send(newState)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        didIceGatheringStateChanged.send(newState)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        didGenerateIceCandidate.send(candidate)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        didRemoveIceCandidates.send(candidates)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        didOpenDataChannel.send(dataChannel)
    }
}

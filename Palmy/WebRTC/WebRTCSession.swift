import Combine
import OSLog
import WebRTC

class WebRTCSession: NSObject {
    private static let iceServers = [
        "stun:46.19.66.12:3478",
        "stun:46.19.66.12:3479"
    ]

    private static let defaultMediaConstraints = {
        let mandatoryConstraints = [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
        ]

        return RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
    }()

    private static let factory = {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()

        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()

    weak var delegate: (any WebRTCSessionDelegate)?

    private(set) var peerConnection: RTCPeerConnection?

    private(set) var audioSession: RTCAudioSession?

    private(set) var cameraVideoCapturer: RTCCameraVideoCapturer?

    private(set) var localAudioTrack: RTCAudioTrack?
    private(set) var localVideoTrack: RTCVideoTrack?

    private(set) var remoteVideoTrack: RTCVideoTrack?

    // MARK: - Public Functions

    func connect() {
        setupPeerConnection()
        setupMediaSenders()
    }

    func disconnect() {
        peerConnection?.close()
        peerConnection = nil
        cameraVideoCapturer = nil
        localAudioTrack = nil
        localVideoTrack = nil
        remoteVideoTrack = nil
    }

    // RTCPeerConnection methods offer, answer, setLocalDescription are executing their completionHandlers on some background thread.

    func getOfferSessionDescription(completionHander: @escaping (Result<RTCSessionDescription, Error>) -> Void) {
        assert(peerConnection != nil)

        peerConnection?.offer(for: Self.defaultMediaConstraints) { [self] sessionDescription, error in
            guard let sessionDescription = sessionDescription else { return }

            self.peerConnection?.setLocalDescription(sessionDescription) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completionHander(.failure(error))
                    } else {
                        completionHander(.success(sessionDescription))
                    }
                }
            }
        }
    }

    func getAnswerSessionDescription(completionHander: @escaping (Result<RTCSessionDescription, Error>) -> Void) {
        assert(peerConnection != nil)

        peerConnection?.answer(for: Self.defaultMediaConstraints) { [self] sessionDescription, error in
            guard let sessionDescription = sessionDescription else { return }
            
            peerConnection?.setLocalDescription(sessionDescription) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completionHander(.failure(error))
                    } else {
                        completionHander(.success(sessionDescription))
                    }
                }
            }
        }
    }

    func setRemoteSessionDescription(_ sessionDescription: RTCSessionDescription, completionHandler: @escaping (Error?) -> ()) {
        assert(peerConnection != nil)

        peerConnection?.setRemoteDescription(sessionDescription) { error in
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }
    }

    func addRemoteCandidate(_ candidate: RTCIceCandidate, completionHandler: @escaping (Error?) -> ()) {
        assert(peerConnection != nil)

        peerConnection?.add(candidate) { error in
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }
    }

    func startRenderLocalVideo(_ videoRenderer: RTCVideoRenderer) {
        localVideoTrack?.add(videoRenderer)
    }

    func startRenderRemoteVideo(_ videoRenderer: RTCVideoRenderer) {
        remoteVideoTrack?.add(videoRenderer)
    }

    // MARK: - Private Functions

    private func setupPeerConnection() {
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: Self.iceServers)]
        configuration.continualGatheringPolicy = .gatherContinually
        configuration.sdpSemantics = .unifiedPlan

        peerConnection = Self.factory.peerConnection(with: configuration, constraints: Self.defaultMediaConstraints, delegate: self)!
    }

    private func setupMediaSenders() {
        audioSession = RTCAudioSession.sharedInstance()

        localAudioTrack = createLocalAudioTrack()
        peerConnection?.add(localAudioTrack!, streamIds: ["stream"])

        localVideoTrack = createLocalVideoTrack()
        peerConnection?.add(localVideoTrack!, streamIds: ["stream"])

        remoteVideoTrack = createRemoteVideoTrack()
    }

    private func createLocalAudioTrack() -> RTCAudioTrack {
        let audioSource = Self.factory.audioSource(with: Self.defaultMediaConstraints)

        return Self.factory.audioTrack(with: audioSource, trackId: "audio0")
    }

    private func createLocalVideoTrack() -> RTCVideoTrack {
        let videoSource = Self.factory.videoSource()

        cameraVideoCapturer = RTCCameraVideoCapturer(delegate: videoSource)

        return Self.factory.videoTrack(with: videoSource, trackId: "video0")
    }

    private func createRemoteVideoTrack() -> RTCVideoTrack? {
        return peerConnection?.transceivers.first(where: { $0.mediaType == .video })?.receiver.track as? RTCVideoTrack
    }
}

extension WebRTCSession: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        let state: String

        switch newState {
        case .new:
            state = "new"
        case .connecting:
            state = "connecting"
        case .connected:
            state = "connected"
        case .disconnected:
            state = "disconnected"
        case .failed:
            state = "failed"
        case .closed:
            state = "closed"
        @unknown default:
            fatalError()
        }

        Logger.general.log("Peer connection state did change to \(state)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        let state: String

        switch stateChanged {
        case .stable:
            state = "stable"
        case .haveLocalOffer:
            state = "haveLocalOffer"
        case .haveLocalPrAnswer:
            state = "haveLocalPrAnswer"
        case .haveRemoteOffer:
            state = "haveRemoteOffer"
        case .haveRemotePrAnswer:
            state = "haveRemotePrAnswer"
        case .closed:
            state = "closed"
        @unknown default:
            fatalError()
        }

        Logger.general.log("Peer connection signaling state did change to \(state)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state: String

        switch newState {
        case .new:
            state = "new"
        case .checking:
            state = "checking"
        case .connected:
            state = "connected"
        case .completed:
            state = "completed"
        case .failed:
            state = "failed"
        case .disconnected:
            state = "disconnected"
        case .closed:
            state = "closed"
        case .count:
            state = "count"
        @unknown default:
            fatalError()
        }

        Logger.general.log("Ice connection state did change to \(state).")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        let state: String

        switch newState {
        case .new:
            state = "new"
        case .gathering:
            state = "gathering"
        case .complete:
            state = "complete"
        @unknown default:
            fatalError()
        }

        Logger.general.log("Ice gathering state did change to \(state).")
    }


    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.webRTCSession(self, didGenerate: candidate)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        delegate?.webRTCSession(self, didRemove: candidates)
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}


    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        Logger.general.log("Stream with \(stream.videoTracks.count) video tracks and \(stream.audioTracks.count) audio tracks was added.")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        Logger.general.log("Stream with \(stream.videoTracks.count) video tracks and \(stream.audioTracks.count) audio tracks was removed.")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}

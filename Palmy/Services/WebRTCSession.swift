import Combine
import OSLog
import WebRTC

class WebRTCSession {
    private let iceServers = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302",
    ]

    private let defaultMediaConstraints = {
        let mandatoryConstraints = [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
        ]

        return RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
    }()

    private let factory = {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()

        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()

    private var cancellables = Set<AnyCancellable>()

    var didGenerateIceCandidate = PassthroughSubject<RTCIceCandidate, Never>()
    var didRemoveIceCandidates = PassthroughSubject<[RTCIceCandidate], Never>()

    private var peerConnectionDelegate: PeerConnectionDelegate?
    var peerConnection: RTCPeerConnection?

    var videoCapturer: RTCVideoCapturer?

    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?

    var remoteVideoTrack: RTCVideoTrack?

    init() {
        setupPeerConnection()
        setupMediaSenders()
    }

    // MARK: - Public

    func getOfferSessionDescription(completionHander: @escaping (_ sessionDescription: RTCSessionDescription) -> Void) {
        peerConnection?.offer(for: defaultMediaConstraints) { [self] sessionDescription, error in
            guard let sessionDescription = sessionDescription else { return }

            peerConnection?.setLocalDescription(sessionDescription) { error in
                completionHander(sessionDescription)
            }
        }
    }

    func getAnswerSessionDescription(completionHandler: @escaping (_ sessionDescription: RTCSessionDescription) -> Void) {
        peerConnection?.answer(for: defaultMediaConstraints) { [self] sessionDescription, error in
            guard let sessionDescription = sessionDescription else { return }

            peerConnection?.setLocalDescription(sessionDescription) { error in
                completionHandler(sessionDescription)
            }
        }
    }

    func setRemoteSessionDescription(_ sessionDescription: RTCSessionDescription, completionHandler: @escaping (Error?) -> ()) {
        peerConnection?.setRemoteDescription(sessionDescription, completionHandler: completionHandler)
    }

    func addRemoteCandidate(_ candidate: RTCIceCandidate, completionHandler: @escaping (Error?) -> ()) {
        peerConnection?.add(candidate, completionHandler: completionHandler)
    }

    func startRenderLocalVideo(_ videoRenderer: RTCVideoRenderer) {
        localVideoTrack?.add(videoRenderer)
    }

    func startRenderRemoteVideo(_ videoRenderer: RTCVideoRenderer) {
        remoteVideoTrack?.add(videoRenderer)
    }

    // MARK: - Private

    private func setupPeerConnection() {
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        configuration.iceServers = [RTCIceServer(urlStrings: iceServers)]

        peerConnectionDelegate = PeerConnectionDelegate()
        peerConnection = factory.peerConnection(with: configuration, constraints: defaultMediaConstraints, delegate: peerConnectionDelegate)!

        peerConnectionDelegate?.didGenerateIceCandidate
            .sink { [weak self] iceCandidate in
                self?.didGenerateIceCandidate.send(iceCandidate)
            }
            .store(in: &cancellables)

        peerConnectionDelegate?.didRemoveIceCandidates
            .sink { [weak self] iceCandidates in
                self?.didRemoveIceCandidates.send(iceCandidates)
            }
            .store(in: &cancellables)
    }

    private func setupMediaSenders() {
//        localAudioTrack = createLocalAudioTrack()
//        peerConnection?.add(localAudioTrack!, streamIds: ["stream"])

        localVideoTrack = createLocalVideoTrack()
        peerConnection?.add(localVideoTrack!, streamIds: ["stream"])

        remoteVideoTrack = createRemoteVideoTrack()
    }

    private func createLocalAudioTrack() -> RTCAudioTrack {
        let audioSource = factory.audioSource(with: defaultMediaConstraints)

        return factory.audioTrack(with: audioSource, trackId: "audio0")
    }

    private func createLocalVideoTrack() -> RTCVideoTrack {
        let videoSource = factory.videoSource()

#if !targetEnvironment(simulator)
        let cameraVideoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        videoCapturer = cameraVideoCapturer
#else
        let fileVideoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        videoCapturer = fileVideoCapturer
#endif

        return factory.videoTrack(with: videoSource, trackId: "video0")
    }

    private func createRemoteVideoTrack() -> RTCVideoTrack? {
        return peerConnection?.transceivers.first(where: { $0.mediaType == .video })?.receiver.track as? RTCVideoTrack
    }
}

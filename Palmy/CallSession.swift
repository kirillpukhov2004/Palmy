import OSLog
import FirebaseFirestore
import WebRTC

enum CallSessionConnectionState {
    case disconnected
    case connecting
    case connected
}

enum CallSessionError: Error {
    case roomNotFound
}

class CallSession: NSObject {
    private let signalingServerSession: SignalingServerSession
    private let webRTCSession = WebRTCSession()

    weak var delegate: CallSessionDelegate?

    var roomID: String?

    var connectionState: CallSessionConnectionState {
        didSet {
            delegate?.callSession(self, didChange: connectionState)
        }
    }

    init(signalingServerSession: SignalingServerSession) {
        self.signalingServerSession = signalingServerSession
        
        self.connectionState = .disconnected

        super.init()

        self.signalingServerSession.delegate = self
        self.webRTCSession.delegate = self
    }

    // MARK: - Public Functions

    func start(with roomID: String?) {
        connectionState = .connecting

        webRTCSession.connect()
        startMediaCapturing()

        if let roomID = roomID {
            signalingServerSession.joinRoom(with: roomID) { [weak self] result in
                guard case .success(let sessionDescription) = result else {
                    if case .failure(let error) = result {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    return
                }

                self?.webRTCSession.setRemoteSessionDescription(sessionDescription) { error in
                    if let error = error {
                        Logger.general.error("\(error.localizedDescription)")

                        return
                    }

                    self?.webRTCSession.getAnswerSessionDescription { result in
                        guard case .success(let sessionDescription) = result else {
                            if case .failure(let error) = result {
                                Logger.general.error("\(error.localizedDescription)")
                            }

                            return
                        }

                        do {
                            let message = try SignalingServerMessage(sessionDescription)

                            try self?.signalingServerSession.send(message)
                        } catch {
                            Logger.general.error("\(error.localizedDescription)")
                        }

                        self?.roomID = roomID
                        self?.connectionState = .connected
                    }
                }
            }
        } else {
            signalingServerSession.createRoom { [weak self] result in
                guard case .success(let roomID) = result else {
                    if case .failure(let error) = result {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    return
                }

                self?.webRTCSession.getOfferSessionDescription { result in
                    guard case .success(let sessionDescription) = result else {
                        if case .failure(let error) = result {
                            Logger.general.error("\(error.localizedDescription)")
                        }

                        return
                    }

                    do {
                        let message = try SignalingServerMessage(sessionDescription)

                        try self?.signalingServerSession.send(message)
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    self?.roomID = roomID
                    self?.connectionState = .connected
                }
            }
        }
    }

    func end() {
        stopMediaCapturing()
        signalingServerSession.leaveRoom()
        webRTCSession.disconnect()

        delegate?.callSessionDidStopRemoteVideoCapturing(self)

        roomID = nil
    }

    func startCameraPreview(_ cameraPreviewView: RTCCameraPreviewView) {
        webRTCSession.startCameraPreview(cameraPreviewView)
    }

    func startRenderRemoteVideo(_ renderer: RTCVideoRenderer) {
        webRTCSession.startRenderRemoteVideo(renderer)
    }

    func setMicrophoneEnabled(_ isMicrophoneEnabled: Bool) {
        do {
            try webRTCSession.configureAudioSession()
            try webRTCSession.setMicrophoneEnabled(isMicrophoneEnabled)
        } catch {
            Logger.general.fault("\(error.localizedDescription)")
        }
    }

    func setCameraEnabled(_ isCameraEnabled: Bool) {
        webRTCSession.setCameraEnabled(isCameraEnabled)
    }

    // MARK: - Private Functions

    private func startMediaCapturing() {
        setMicrophoneEnabled(true)
        setCameraEnabled(true)
    }

    private func stopMediaCapturing() {
        setMicrophoneEnabled(false)
        setCameraEnabled(false)
    }
}

// MARK: - WebRTCSessionDelegate

extension CallSession: WebRTCSessionDelegate {
    func webRTCSession(_ webRTCSession: WebRTCSession, didGenerate iceCandidate: RTCIceCandidate) {
        do {
            let message = try SignalingServerMessage(iceCandidate)

            try signalingServerSession.send(message)
        } catch {
            Logger.general.error("\(error.localizedDescription)")
        }
    }
}

// MARK: - SignalingServerSessionDelegate

extension CallSession: SignalingServerSessionDelegate {
    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteSessionDescription: RTCSessionDescription) {
        webRTCSession.setRemoteSessionDescription(remoteSessionDescription) { error in
            if let error = error {
                Logger.general.fault("\(error.localizedDescription)")
            }
        }
    }

    func signalingServerSession(_ signalingServerSession: SignalingServerSession, didRecieve remoteIceCadidate: RTCIceCandidate) {
        webRTCSession.addRemoteCandidate(remoteIceCadidate) { error in
            if let error = error {
                Logger.general.fault("\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - RTCAudioSessionDelegate

extension CallSession: RTCAudioSessionDelegate {
    func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        Logger.general.log("\(#function)")
    }

    func audioSessionDidStopPlayOrRecord(_ session: RTCAudioSession) {
        Logger.general.log("\(#function)")
    }
}

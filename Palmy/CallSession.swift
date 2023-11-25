import OSLog
import FirebaseFirestore
import WebRTC

enum CallSessionConnectionState {
    case disconnected
    case connecting
    case connected
}

protocol CallSessionDelegate: AnyObject {
    func callSession(_ callSession: CallSession, didChange connectionState: CallSessionConnectionState)

    func callSession(_ callSession: CallSession, didStartCameraCapturing captureSession: AVCaptureSession)
    func callSessionDidStopCameraCapturing(_ callSession: CallSession)

    func callSession(_ callSession: CallSession, didStartRemoteVideoCapturing videoTrack: RTCVideoTrack)
    func callSessionDidStopRemoteVideoCapturing(_ callSession: CallSession)
}

enum CallSessionError: Error {
    case roomNotFound
}

class CallSession: NSObject {
    private let signalingServerSession: SignalingServerSession
    private let webRTCSession = WebRTCSession()

    private var videoCaptureController: (any VideoCaptureController)?

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

    func setMicrophoneEnabled(_ isAudioEnabled: Bool) {
        webRTCSession.localAudioTrack?.isEnabled = isAudioEnabled
    }

    func setCameraEnabled(_ isVideoEnabled: Bool) {
        webRTCSession.localVideoTrack?.isEnabled = isVideoEnabled
    }

    // MARK: - Private Functions

    private func startMediaCapturing() {
        if let cameraVideoCapturer = webRTCSession.cameraVideoCapturer {
            videoCaptureController = CameraVideoCaptureController(capturer: cameraVideoCapturer)
            videoCaptureController!.startCapture()

            delegate?.callSession(self, didStartCameraCapturing: cameraVideoCapturer.captureSession)
        }

        if let audioSession = webRTCSession.audioSession {
            let audioSessionConfiguration = RTCAudioSessionConfiguration()
            audioSessionConfiguration.categoryOptions = .duckOthers
            audioSessionConfiguration.category = AVAudioSession.Category.playAndRecord.rawValue
            audioSessionConfiguration.mode = AVAudioSession.Mode.videoChat.rawValue

            audioSession.lockForConfiguration()

            do {
                try audioSession.setConfiguration(audioSessionConfiguration)
                try audioSession.setActive(true)
            } catch {
                Logger.general.error("\(error.localizedDescription)")
            }

            audioSession.unlockForConfiguration()
        }

        if let remoteVideoTrack = webRTCSession.remoteVideoTrack {
            delegate?.callSession(self, didStartRemoteVideoCapturing: remoteVideoTrack)
        }
    }

    private func stopMediaCapturing() {
        if let audioSession = webRTCSession.audioSession {
            audioSession.lockForConfiguration()

            do {
                try webRTCSession.audioSession?.setActive(false)
            } catch {
                Logger.general.error("\(error.localizedDescription)")
            }

            audioSession.unlockForConfiguration()
        }


        if let videoCaptureController = videoCaptureController as? CameraVideoCaptureController {
            videoCaptureController.stopCapture()
            delegate?.callSessionDidStopCameraCapturing(self)
        }
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

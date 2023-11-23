import UIKit
import Combine
import OSLog
import SnapKit
import WebRTC

class MainViewController: UIViewController {
    var signalingServerSession: SignalingServerSession

    var webRTCSession: WebRTCSession

    var videoCaptureController: (any VideoCaptureController)!

    var cancellables = Set<AnyCancellable>()

    private var infoButton: UIButton!

    private var mainToolBarView: MainToolBarView!

//    private var localVideoView: RTCMTLVideoView!
    private var localVideoView: RTCCameraPreviewView!

    private var remoteVideoView: RTCMTLVideoView!

    var room: Room? {
        didSet {
            DispatchQueue.main.async {
                self.infoButton.isHidden = self.room == nil
            }
        }
    }

    init(signalingServerSession: SignalingServerSession, webRtcSession: WebRTCSession) {
        self.signalingServerSession = signalingServerSession
        self.webRTCSession = webRtcSession

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        infoButton = UIButton(type: .custom)
        infoButton.addTarget(self, action: #selector(infoButtonPressed), for: .touchUpInside)
        infoButton.setImage(UIImage(systemName: "info.circle")!, for: .normal)
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.contentHorizontalAlignment = .fill
        infoButton.contentVerticalAlignment = .fill
        infoButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        infoButton.backgroundColor = .clear
        infoButton.tintColor = .systemGreen
        infoButton.isHidden = true
        view.addSubview(infoButton)

        mainToolBarView = MainToolBarView()

        mainToolBarView.didCreateRoomButtonPressed
            .sink { [weak self] in
                self?.startCall()
            }
            .store(in: &cancellables)

        mainToolBarView.didJoinRoomButtonPressed
            .sink { [weak self] in
                let alertController = UIAlertController(title: nil, message: "Enter CallID", preferredStyle: .alert)
                alertController.addTextField()

                let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
                    let textField = alertController.textFields!.first!
                    if let callID = textField.text, !callID.isEmpty {
                        self?.connectToCall(with: callID)
                    }
                }
                alertController.addAction(continueAction)

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alertController.addAction(cancelAction)

                DispatchQueue.main.async {
                    self?.present(alertController, animated: true)
                }
            }
            .store(in: &cancellables)

        mainToolBarView.didLeaveRoomButtonPressed
            .sink { [weak self] in
                self?.endCall()
            }
            .store(in: &cancellables)

        view.addSubview(mainToolBarView)

        localVideoView = RTCCameraPreviewView()
        (localVideoView.layer as! AVCaptureVideoPreviewLayer).videoGravity = .resizeAspectFill
        view.insertSubview(localVideoView, at: 0)

        remoteVideoView = RTCMTLVideoView()
        remoteVideoView.layer.cornerRadius = 13
        remoteVideoView.layer.masksToBounds = true
        view.insertSubview(remoteVideoView, aboveSubview: localVideoView)

        localVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        remoteVideoView.snp.makeConstraints { make in
            make.trailing.equalTo(localVideoView).offset(-16)
            make.bottom.equalTo(mainToolBarView.snp.top).offset(-16)
            make.height.equalTo(localVideoView).multipliedBy(0.35)
            make.width.equalTo(localVideoView.snp.height).multipliedBy(9/16 * 0.35)
        }

        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(8)
            make.width.height.equalTo(Constants.smallCircleButtonRadius)
        }

        mainToolBarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @objc private func infoButtonPressed() {
        guard let room = room else { return }

        let viewController = RoomDetailsViewController(room: room)
        present(viewController, animated: true)
    }

    private func startMediaCapturing() {
#if targetEnvironment(simulator)
                guard let fileVideoCapturer = webRTCSession.videoCapturer as? RTCFileVideoCapturer else {
                    fatalError()
                }

                videoCaptureController = FileVideoCaptureController(capturer: fileVideoCapturer)
#else
                guard let cameraVideoCapturer = webRTCSession.videoCapturer as? RTCCameraVideoCapturer else {
                    fatalError()
                }

                localVideoView.captureSession = cameraVideoCapturer.captureSession
                videoCaptureController = CameraVideoCaptureController(capturer: cameraVideoCapturer)
#endif

        videoCaptureController.startCapture()
        webRTCSession.startRenderRemoteVideo(remoteVideoView)

        let webRTCConfiguration = RTCAudioSessionConfiguration()
        webRTCConfiguration.categoryOptions = .defaultToSpeaker
        RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)

        let audioSession = RTCAudioSession.sharedInstance()
        audioSession.add(self)

        let audioSessionConfiguration = RTCAudioSessionConfiguration()
        audioSessionConfiguration.category = AVAudioSession.Category.ambient.rawValue
        audioSessionConfiguration.categoryOptions = .duckOthers
        audioSessionConfiguration.mode = AVAudioSession.Mode.default.rawValue
        let _audioSession = RTCAudioSession.sharedInstance()
        do {
            _audioSession.lockForConfiguration()
            if _audioSession.isActive {
                try _audioSession.setConfiguration(audioSessionConfiguration)
            } else {
                try _audioSession.setConfiguration(audioSessionConfiguration, active: true)
            }   
            _audioSession.unlockForConfiguration()
        } catch {
            Logger.general.error("\(error.localizedDescription)")
        }
    }

    private func startCall() {
        webRTCSession.connect()

        signalingServerSession.createRoom { [weak self] result in
            guard case .success(let room) = result else {
                if case .failure(let error) = result {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            self?.webRTCSession.getOfferSessionDescription { [weak self] result in
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

                self?.room = room
                self?.mainToolBarView.state = .insideRoom

                self?.startMediaCapturing()

                self?.signalingServerSession.delegate = self
                self?.webRTCSession.delegate = self
            }
        }
    }

    private func connectToCall(with roomId: String) {
        webRTCSession.connect()

        signalingServerSession.joinRoom(with: roomId) { [weak self] result in
            guard case .success((let room, let sessionDescription)) = result else {
                if case .failure(let error) = result {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            assert(Thread.isMainThread)

            self?.webRTCSession.setRemoteSessionDescription(sessionDescription) { error in
                if let error = error {
                    Logger.general.error("\(error.localizedDescription)")

                    return
                }

                self?.webRTCSession.getAnswerSessionDescription { [weak self] result in
                    guard case .success(let sessionDescription) = result else {
                        if case .failure(let error) = result {
                            Logger.general.error("\(error.localizedDescription)")
                        }

                        return
                    }

                    do {
                        let message = try SignalingServerMessage(sessionDescription)

                        try self?.signalingServerSession.send(message)

                        self?.signalingServerSession.delegate = self
                        self?.webRTCSession.delegate = self
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    self?.room = room
                    self?.mainToolBarView.state = .insideRoom

                    self?.startMediaCapturing()
                }
            }
        }
    }

    private func endCall() {
        signalingServerSession.leaveRoom()
        webRTCSession.disconnect()
        localVideoView.captureSession = nil

        room = nil
        mainToolBarView.state = .outsideRoom
    }

    private enum Constants {
        static let standardCircleButtonRadius = CGFloat(64)
        static let standardCircleButtonCornerRadius = CGFloat(32)

        static let smallCircleButtonRadius = CGFloat(32)
        static let smallCircleButtonCornerRadius = CGFloat(16)
    }
}

extension MainViewController: WebRTCSessionDelegate {
    func webRTCSession(_ webRTCSession: WebRTCSession, didGenerate iceCandidate: RTCIceCandidate) {
        do {
            let message = try SignalingServerMessage(iceCandidate)

            try signalingServerSession.send(message)
        } catch {
            Logger.general.error("\(error.localizedDescription)")
        }
    }
}

extension MainViewController: SignalingServerSessionDelegate {
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

extension MainViewController: RTCAudioSessionDelegate {
    func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        Logger.general.log("\(#function)")
    }

    func audioSessionDidStopPlayOrRecord(_ session: RTCAudioSession) {
        Logger.general.log("\(#function)")
    }
}

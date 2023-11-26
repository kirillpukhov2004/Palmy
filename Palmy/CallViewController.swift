import UIKit
import OSLog
import WebRTC
import FirebaseFirestore

final class CallViewController: UIViewController {
    var callSession: CallSession

    private var infoButton: UIButton!

    private var shareButton: UIButton!

    private var callToolBarView: CallToolBarView!

    private var cameraPreviewView: RTCCameraPreviewView!
    private var remoteVideoView: RTCMTLVideoView!

    private var isMicrophoneEnabled: Bool {
        didSet {
            callSession.setMicrophoneEnabled(isMicrophoneEnabled)
        }
    }

    private var isCameraEnabled: Bool {
        didSet {
            callSession.setCameraEnabled(isCameraEnabled)
        }
    }

    private var cameraPosition: AVCaptureDevice.Position

    var roomID: String?

    init(roomID: String?) {
        self.roomID = roomID

        isMicrophoneEnabled = true
        isCameraEnabled = true
        cameraPosition = .front

        let firestore = Firestore.firestore()
        callSession = CallSession(signalingServerSession: FirestoreSignalingServerSession(firestore: firestore))

        super.init(nibName: nil, bundle: nil)

        callSession.delegate = self
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

        shareButton = UIButton(type: .custom)
        shareButton.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        let shareButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .medium))
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: shareButtonSymbolConfiguration)!, for: .normal)
        shareButton.contentHorizontalAlignment = .center
        shareButton.contentVerticalAlignment = .center
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        shareButton.backgroundColor = .clear
        shareButton.tintColor = .white
        shareButton.layer.cornerRadius = 20
        shareButton.layer.masksToBounds = true
        view.addSubview(shareButton)

        let shareButtonVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        shareButtonVisualEffectView.isUserInteractionEnabled = false
        shareButton.insertSubview(shareButtonVisualEffectView, belowSubview: shareButton.imageView!)
        shareButtonVisualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        callToolBarView = CallToolBarView()
        callToolBarView.delegate = self

        view.addSubview(callToolBarView)

        cameraPreviewView = RTCCameraPreviewView()
        (cameraPreviewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = .resizeAspectFill
        view.insertSubview(cameraPreviewView, at: 0)

        remoteVideoView = RTCMTLVideoView()
        remoteVideoView.layer.cornerRadius = 13
        remoteVideoView.layer.masksToBounds = true
        view.insertSubview(remoteVideoView, aboveSubview: cameraPreviewView)

        shareButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(8)
            make.width.height.equalTo(40)
        }

        cameraPreviewView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        remoteVideoView.snp.makeConstraints { make in
            make.trailing.equalTo(cameraPreviewView).offset(-16)
            make.bottom.equalTo(callToolBarView.snp.top).offset(-16)
            make.height.equalTo(cameraPreviewView).multipliedBy(0.35)
            make.width.equalTo(cameraPreviewView.snp.height).multipliedBy(9/16 * 0.35)
        }

        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(8)
            make.width.height.equalTo(Constants.smallCircleButtonRadius)
        }

        callToolBarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8)
        }
    }

    override func viewDidLoad() {
        startCall()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @objc private func infoButtonPressed() {
        let room = Room(id: roomID!, participants: [])

        let viewController = RoomDetailsViewController(room: room)
        present(viewController, animated: true)
    }

    @objc private func shareButtonPressed() {
        guard let roomID = roomID else { return }

        let viewController = UIActivityViewController(activityItems: [roomID], applicationActivities: nil)

        present(viewController, animated: true)
    }

    private func startCall() {
        callSession.start(with: roomID)
    }

    private func endCall() {
        callSession.end()

        dismiss(animated: true)
    }

    private enum Constants {
        static let standardCircleButtonRadius = CGFloat(64)
        static let standardCircleButtonCornerRadius = CGFloat(32)

        static let smallCircleButtonRadius = CGFloat(32)
        static let smallCircleButtonCornerRadius = CGFloat(16)
    }
}

// MARK: - CallToolBarViewDelegate

extension CallViewController: CallToolBarViewDelegate {
    func callToolBarViewDidLeaveRoomButtonPressed(_ callToolBarView: CallToolBarView) {
        endCall()
    }

    func callToolBarViewDidCameraToggleButtonPressed(_ callToolBarView: CallToolBarView) {
        isCameraEnabled.toggle()
    }

    func callToolBarViewDidMicrophoneToggleButtonPressed(_ callToolBarView: CallToolBarView) {
        isMicrophoneEnabled.toggle()
    }
}

// MARK: - CallSessionDelegate

extension CallViewController: CallSessionDelegate {
    func callSession(_ callSession: CallSession, didChange connectionState: CallSessionConnectionState) {
        switch connectionState {
        case .disconnected:
            Logger.general.log("Call session state did change to disconnected")

            infoButton.isHidden = true
        case .connecting:
            Logger.general.log("Call session state did change to connetcting")
        case .connected:
            Logger.general.log("Call session state did change to connected")
            
            assert(callSession.roomID != nil)

            roomID = callSession.roomID

            callSession.startCameraPreview(cameraPreviewView)
            callSession.startRenderRemoteVideo(remoteVideoView)
        }
    }

    func callSession(_ callSession: CallSession, didStartCameraCapturing captureSession: AVCaptureSession) {
        cameraPreviewView.captureSession = captureSession
    }

    func callSessionDidStopCameraCapturing(_ callSession: CallSession) {

    }

    func callSession(_ callSession: CallSession, didStartRemoteVideoCapturing videoTrack: RTCVideoTrack) {
        videoTrack.add(remoteVideoView)
    }

    func callSessionDidStopRemoteVideoCapturing(_ callSession: CallSession) {}
}


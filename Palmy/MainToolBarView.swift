import UIKit
import Combine

enum MainToolBarViewState {
    case outsideRoom
    case insideRoom
}

class MainToolBarView: UIView {
    private var createRoomButton: UIButton!

    private var joinRoomButton: UIButton!

    private var leaveRoomButton: UIButton!

    private var cameraToggleButton: UIButton!

    private var microphoneToggleButton: UIButton!

    private var backgroundVisualEffectView: UIVisualEffectView!

    var state: MainToolBarViewState = .outsideRoom {
        didSet {
            didStateChanged()
        }
    }

    var didCreateRoomButtonPressed = PassthroughSubject<Void, Never>()
    var didJoinRoomButtonPressed = PassthroughSubject<Void, Never>()
    var didLeaveRoomButtonPressed = PassthroughSubject<Void, Never>()
    var didCameraToggleButtonPressed = PassthroughSubject<Void, Never>()
    var didMicrophoneToggleButtonPressed = PassthroughSubject<Void, Never>()

    override var intrinsicContentSize: CGSize {
        let size: CGSize

        switch state {
        case .outsideRoom:
            size = CGSize(
                width: Constants.standardCircleButtonRadius * 4 + Constants.padding * 2,
                height: Constants.standardCircleButtonRadius + Constants.padding * 2
            )
        case .insideRoom:
            size = CGSize(
                width: Constants.standardCircleButtonRadius * (3 * 2 - 1) + Constants.padding * 2,
                height: Constants.standardCircleButtonRadius + Constants.padding * 2
            )
        }

        return size
    }

    init() {
        super.init(frame: .zero)

        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear

        createRoomButton = UIButton(type: .custom)
        createRoomButton.addTarget(self, action: #selector(createRoomButtonPressed), for: .touchUpInside)
        let createRoomButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 26, weight: .regular))
        createRoomButton.setImage(UIImage(systemName: "phone.badge.plus", withConfiguration: createRoomButtonSymbolConfiguration)!, for: .normal)
        createRoomButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        createRoomButton.backgroundColor = UIColor(cgColor: CGColor(red: 39/255, green: 190/255, blue: 76/255, alpha: 1.0))
        createRoomButton.tintColor = .white
        createRoomButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        addSubview(createRoomButton)

        joinRoomButton = UIButton(type: .custom)
        joinRoomButton.addTarget(self, action: #selector(joinToRoomButtonPressed), for: .touchUpInside)
        let joinRoomButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 26, weight: .regular))
        joinRoomButton.setImage(UIImage(systemName: "globe", withConfiguration: joinRoomButtonSymbolConfiguration)!, for: .normal)
        joinRoomButton.backgroundColor = .systemBlue
        joinRoomButton.tintColor = .white
        joinRoomButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        addSubview(joinRoomButton)

        leaveRoomButton = UIButton(type: .custom)
        leaveRoomButton.addTarget(self, action: #selector(leaveRoomButtonPressed), for: .touchUpInside)
        let leaveRoomButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 26, weight: .regular))
        leaveRoomButton.setImage(UIImage(systemName: "phone.down.fill", withConfiguration: leaveRoomButtonSymbolConfiguration)!, for: .normal)
        leaveRoomButton.imageView?.contentMode = .scaleAspectFit
        leaveRoomButton.backgroundColor = .systemRed
        leaveRoomButton.tintColor = .white
        leaveRoomButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        leaveRoomButton.isHidden = true
        addSubview(leaveRoomButton)

        cameraToggleButton = UIButton(type: .custom)
        cameraToggleButton.addTarget(self, action: #selector(cameraToggleButtonPressed), for: .touchUpInside)
        let cameraToggleButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 22, weight: .regular))
        cameraToggleButton.setImage(UIImage(systemName: "camera.fill", withConfiguration: cameraToggleButtonSymbolConfiguration)!, for: .normal)
        cameraToggleButton.backgroundColor = .clear
        cameraToggleButton.tintColor = .white
        cameraToggleButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        cameraToggleButton.layer.masksToBounds = true
        cameraToggleButton.isHidden = true
        addSubview(cameraToggleButton)

        let cameraToggleButtonBackgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        cameraToggleButton.insertSubview(cameraToggleButtonBackgroundVisualEffectView, belowSubview: cameraToggleButton.imageView!)
        cameraToggleButtonBackgroundVisualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        microphoneToggleButton = UIButton(type: .custom)
        microphoneToggleButton.addTarget(self, action: #selector(cameraToggleButtonPressed), for: .touchUpInside)
        let microphoneTogglButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 22, weight: .regular))
        microphoneToggleButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: microphoneTogglButtonSymbolConfiguration)!, for: .normal)
        cameraToggleButton.backgroundColor = .clear
        microphoneToggleButton.tintColor = .white
        microphoneToggleButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        microphoneToggleButton.layer.masksToBounds = true
        microphoneToggleButton.isHidden = true
        addSubview(microphoneToggleButton)

        let microphoneTogglButtonBackgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        microphoneToggleButton.insertSubview(microphoneTogglButtonBackgroundVisualEffectView, belowSubview: microphoneToggleButton.imageView!)
        microphoneTogglButtonBackgroundVisualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        backgroundVisualEffectView = UIVisualEffectView(effect: blurEffect)
        backgroundVisualEffectView.layer.cornerRadius = (Constants.standardCircleButtonRadius + Constants.padding * 2) / 2
        backgroundVisualEffectView.layer.masksToBounds = true
        insertSubview(backgroundVisualEffectView, at: 0)
    }

    private func setupConstraints() {
        createRoomButton.snp.makeConstraints { make in
            make.leading.equalTo(backgroundVisualEffectView).inset(Constants.padding)
            make.width.height.equalTo(Constants.standardCircleButtonRadius)
            make.centerY.equalTo(backgroundVisualEffectView)
        }

        joinRoomButton.snp.makeConstraints { make in
            make.trailing.equalTo(backgroundVisualEffectView).inset(Constants.padding)
            make.width.height.equalTo(Constants.standardCircleButtonRadius)
            make.centerY.equalTo(backgroundVisualEffectView)
        }

        leaveRoomButton.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.standardCircleButtonRadius)
            make.centerX.equalTo(backgroundVisualEffectView)
            make.centerY.equalTo(backgroundVisualEffectView)
        }

        cameraToggleButton.snp.makeConstraints { make in
            make.leading.equalTo(backgroundVisualEffectView).inset(Constants.padding)
            make.width.height.equalTo(Constants.standardCircleButtonRadius)
            make.centerY.equalTo(backgroundVisualEffectView)
        }

        microphoneToggleButton.snp.makeConstraints { make in
            make.trailing.equalTo(backgroundVisualEffectView).inset(Constants.padding)
            make.width.height.equalTo(Constants.standardCircleButtonRadius)
            make.centerY.equalTo(backgroundVisualEffectView)
        }

        backgroundVisualEffectView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(Constants.standardCircleButtonRadius * 4 + Constants.padding * 2)
            make.height.equalTo(Constants.standardCircleButtonRadius + Constants.padding * 2)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func createRoomButtonPressed() {
        didCreateRoomButtonPressed.send()
    }

    @objc private func joinToRoomButtonPressed() {
        didJoinRoomButtonPressed.send()
    }

    @objc private func leaveRoomButtonPressed() {
        didLeaveRoomButtonPressed.send()
    }

    @objc private func cameraToggleButtonPressed() {
        didCameraToggleButtonPressed.send()
    }

    @objc private func microphoneToggleButtonPressed() {
        didMicrophoneToggleButtonPressed.send()
    }

    private func didStateChanged() {
        switch state {
        case .outsideRoom:
            backgroundVisualEffectView.snp.updateConstraints { make in
                make.width.equalTo(Constants.standardCircleButtonRadius * 4 + Constants.padding * 2)
            }

            createRoomButton.isHidden = false
            joinRoomButton.isHidden = false

            cameraToggleButton.isHidden = true
            microphoneToggleButton.isHidden = true
            leaveRoomButton.isHidden = true
        case .insideRoom:
            backgroundVisualEffectView.snp.updateConstraints { make in
                make.width.equalTo(Constants.standardCircleButtonRadius * (3 * 2 - 1) + Constants.padding * 2)
            }

            createRoomButton.isHidden = true
            joinRoomButton.isHidden = true
            
            cameraToggleButton.isHidden = false
            microphoneToggleButton.isHidden = false
            leaveRoomButton.isHidden = false
        }

//        UIView.animate(withDuration: 1) {
//            self.setNeedsLayout()
//        }
    }

    private enum Constants {
        static let padding = CGFloat(8)

        static let standardCircleButtonRadius = CGFloat(56)
        static let standardCircleButtonCornerRadius = Constants.standardCircleButtonRadius / 2
    }
}

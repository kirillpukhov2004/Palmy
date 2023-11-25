import UIKit
import Combine

protocol CallToolBarViewDelegate: AnyObject {
    func callToolBarViewDidLeaveRoomButtonPressed(_ callToolBarView: CallToolBarView)
    func callToolBarViewDidCameraToggleButtonPressed(_ callToolBarView: CallToolBarView)
    func callToolBarViewDidMicrophoneToggleButtonPressed(_ callToolBarView: CallToolBarView)
}

class CallToolBarView: UIView {
    private var leaveRoomButton: UIButton!

    private var cameraToggleButton: UIButton!

    private var microphoneToggleButton: UIButton!

    private var backgroundVisualEffectView: UIVisualEffectView!

    weak var delegate: CallToolBarViewDelegate?

    override var intrinsicContentSize: CGSize {
        let size: CGSize

        size = CGSize(
            width: Constants.standardCircleButtonRadius * (3 * 2 - 1) + Constants.padding * 2,
            height: Constants.standardCircleButtonRadius + Constants.padding * 2
        )

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

        leaveRoomButton = UIButton(type: .custom)
        leaveRoomButton.addTarget(self, action: #selector(leaveRoomButtonPressed), for: .touchUpInside)
        let leaveRoomButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 26, weight: .regular))
        leaveRoomButton.setImage(UIImage(systemName: "phone.down.fill", withConfiguration: leaveRoomButtonSymbolConfiguration)!, for: .normal)
        leaveRoomButton.imageView?.contentMode = .scaleAspectFit
        leaveRoomButton.backgroundColor = .systemRed
        leaveRoomButton.tintColor = .white
        leaveRoomButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        addSubview(leaveRoomButton)

        cameraToggleButton = UIButton(type: .custom)
        cameraToggleButton.addTarget(self, action: #selector(cameraToggleButtonPressed), for: .touchUpInside)
        let cameraToggleButtonSymbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 22, weight: .regular))
        cameraToggleButton.setImage(UIImage(systemName: "camera.fill", withConfiguration: cameraToggleButtonSymbolConfiguration)!, for: .normal)
        cameraToggleButton.backgroundColor = .clear
        cameraToggleButton.tintColor = .white
        cameraToggleButton.layer.cornerRadius = Constants.standardCircleButtonCornerRadius
        cameraToggleButton.layer.masksToBounds = true
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
            make.width.equalTo(Constants.standardCircleButtonRadius * (3 * 2 - 1) + Constants.padding * 2)
            make.height.equalTo(Constants.standardCircleButtonRadius + Constants.padding * 2)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func leaveRoomButtonPressed() {
        delegate?.callToolBarViewDidLeaveRoomButtonPressed(self)
    }

    @objc private func cameraToggleButtonPressed() {
        delegate?.callToolBarViewDidCameraToggleButtonPressed(self)
    }

    @objc private func microphoneToggleButtonPressed() {
        delegate?.callToolBarViewDidMicrophoneToggleButtonPressed(self)
    }

    private enum Constants {
        static let padding = CGFloat(8)

        static let standardCircleButtonRadius = CGFloat(56)
        static let standardCircleButtonCornerRadius = Constants.standardCircleButtonRadius / 2
    }
}

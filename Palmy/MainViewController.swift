import UIKit
import OSLog
import SnapKit
import WebRTC
import FirebaseFirestore

class MainViewController: UIViewController {
    private var containerView: UIView!

    private var newCallButton: UIButton!

    private var joinCallButton: UIButton!

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        setupViews()
        setupConstraints()
    }

    // MARK: - Private Functions

    private func setupViews() {
        containerView = UIView()
        view.addSubview(containerView)

        newCallButton = UIButton(type: .custom)
        newCallButton.setTitle("New Call", for: .normal)
        newCallButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        newCallButton.addTarget(self, action: #selector(newCallButtonPressed), for: .touchUpInside)
        newCallButton.tintColor = .label
        newCallButton.backgroundColor = UIColor(cgColor: CGColor(red: 28/255, green: 190/255, blue: 76/255, alpha: 1))
        newCallButton.layer.cornerRadius = 13
        newCallButton.layer.cornerCurve = .continuous
        newCallButton.layer.shadowColor = CGColor(red: 28/255, green: 190/255, blue: 76/255, alpha: 1)
        newCallButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        newCallButton.layer.shadowOpacity = 0.5
        newCallButton.layer.shadowRadius = 3
        containerView.addSubview(newCallButton)

        joinCallButton = UIButton(type: .custom)
        joinCallButton.setTitle("Join Call", for: .normal)
        joinCallButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        joinCallButton.addTarget(self, action: #selector(joinCallButtonPressed), for: .touchUpInside)
        joinCallButton.tintColor = .label
        joinCallButton.backgroundColor = UIColor(cgColor: CGColor(red: 11/255, green: 132/255, blue: 255/255, alpha: 1))
        joinCallButton.layer.cornerRadius = 13
        joinCallButton.layer.cornerCurve = .continuous
        joinCallButton.layer.shadowColor = CGColor(red: 11/255, green: 132/255, blue: 255/255, alpha: 1)
        joinCallButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        joinCallButton.layer.shadowOpacity = 0.5
        joinCallButton.layer.shadowRadius = 3
        containerView.addSubview(joinCallButton)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.equalTo(332)
            make.height.equalTo(55)
            make.centerX.equalToSuperview()
        }

        newCallButton.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.height.equalTo(55)
            make.width.equalTo(150)
        }

        joinCallButton.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(55)
            make.width.equalTo(150)
        }
    }

    // MARK: - Actions

    @objc private func newCallButtonPressed() {
        let callViewController = CallViewController(roomID: nil)
        callViewController.modalPresentationStyle = .fullScreen
        callViewController.modalTransitionStyle = .crossDissolve

        present(callViewController, animated: true)
    }

    @objc private func joinCallButtonPressed() {
        let alertController = UIAlertController(title: nil, message: "Enter ID of the room", preferredStyle: .alert)
        alertController.addTextField()

        let connectAlertAction = UIAlertAction(title: "Connect", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first else {
                alertController.dismiss(animated: true)

                return
            }

            if let roomID = textField.text, !roomID.isEmpty {
                let callViewController = CallViewController(roomID: roomID)
                callViewController.modalPresentationStyle = .fullScreen
                callViewController.modalTransitionStyle = .crossDissolve

                self?.present(callViewController, animated: true)
            }
        }

        let cancelAlertAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(connectAlertAction)
        alertController.addAction(cancelAlertAction)

        present(alertController, animated: true)
    }
}

import UIKit
import OSLog
import SnapKit
import AlertKit

class AuthViewController: UIViewController {
    private let authController: AuthController

    private var containerStackView: UIStackView!

    private var loginTextField: AuthTextField!

    private var passwordTextField: AuthTextField!

    private var signInButton: UIButton!

    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Lifecycle

    init(authController: AuthController) {
        self.authController = authController

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        setupViews()
        setupGestureRecognizers()
        setupConstraints()
    }

    // MARK: - Private Functions

    private func setupViews() {
        containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.distribution = .fillProportionally
        containerStackView.alignment = .center
        view.addSubview(containerStackView)

        loginTextField = AuthTextField(type: .login)
        loginTextField.title = "Login"
        loginTextField.delegate = self
        containerStackView.addArrangedSubview(loginTextField)
        containerStackView.setCustomSpacing(14, after: loginTextField)

        passwordTextField = AuthTextField(type: .password)
        passwordTextField.title = "Password"
        passwordTextField.delegate = self
        containerStackView.addArrangedSubview(passwordTextField)
        containerStackView.setCustomSpacing(30, after: passwordTextField)

        signInButton = UIButton(type: .custom)
        signInButton.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        signInButton.backgroundColor = UIColor(cgColor: CGColor(red: 23 / 255, green: 132 / 255, blue: 236 / 255, alpha: 1))
        signInButton.layer.cornerRadius = 10
        signInButton.layer.cornerCurve = .continuous
        containerStackView.addArrangedSubview(signInButton)
    }

    private func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    private func setupConstraints() {
        containerStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        loginTextField.snp.makeConstraints { make in
            make.width.equalTo(255)
            make.height.equalTo(48)
        }

        passwordTextField.snp.makeConstraints { make in
            make.width.equalTo(255)
            make.height.equalTo(48)
        }

        signInButton.snp.makeConstraints { make in
            make.width.equalTo(250)
            make.height.equalTo(40)
        }
    }

    private func handleError(_ error: Error) {
        switch error {
        case AuthControllerError.invalidEmail:
            Logger.general.error("\(error.localizedDescription)")
        case AuthControllerError.wrongPassword:
            let alertView = AlertAppleMusic17View(title: "Wrong password", subtitle: nil, icon: .error)

            alertView.present(on: view)
        case AuthControllerError.invalidLoginCredentials:
            signUp()
        default:
            Logger.general.error("\(error.localizedDescription)")
        }
    }

    private func signIn() {
        if let login = loginTextField.textField.text,
           let password = passwordTextField.textField.text {
            authController.signIn(withEmail: login, password: password) { [weak self] error in
                guard error == nil else {
                    if let error = error {
                        self?.handleError(error)
                    }

                    return
                }

                guard let window = self?.view.window else { return }

                let mainViewController = MainViewController()
                let navigationController = UINavigationController(rootViewController: mainViewController)

                window.rootViewController = navigationController
            }
        }
    }

    private func signUp() {
        if let login = loginTextField.textField.text,
           let password = passwordTextField.textField.text {
            authController.signUp(withEmail: login, password: password) { [weak self] error in
                guard error == nil else {
                    if let error = error {
                        self?.handleError(error)
                    }

                    return
                }

                guard let window = self?.view.window else { return }

                let mainViewController = MainViewController()
                let navigationController = UINavigationController(rootViewController: mainViewController)

                window.rootViewController = navigationController
            }
        }
    }

    // MARK: - Actions

    @objc private func signInButtonPressed() {
        loginTextField.textField.resignFirstResponder()
        passwordTextField.textField.resignFirstResponder()

        signIn()
    }

    @objc private func tapGestureRecognizerAction() {
        if loginTextField.textField.isFirstResponder {
            loginTextField.textField.resignFirstResponder()
        } else if passwordTextField.textField.isFirstResponder {
            passwordTextField.textField.resignFirstResponder()
        }
    }
}

// MARK: - UITextFieldDelegate

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === loginTextField.textField {
            passwordTextField.textField.becomeFirstResponder()
        } else if textField === passwordTextField.textField {
            passwordTextField.textField.resignFirstResponder()
        }

        return true
    }
}

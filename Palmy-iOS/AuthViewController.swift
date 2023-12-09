import UIKit
import OSLog
import SnapKit
import AlertKit

enum AuthTextFieldType {
    case login
    case password
}

class AuthTextField: UITextField {
    private let padding = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    init(type: AuthTextFieldType) {
        super.init(frame: .zero)

        layer.cornerRadius = 10
        layer.masksToBounds = true

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        visualEffectView.isUserInteractionEnabled = false
        insertSubview(visualEffectView, at: 0)
        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        keyboardType = .default
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no

        switch type {
        case .login:
            returnKeyType = .continue

            placeholder = "Login"
        case .password:
            returnKeyType = .done
            isSecureTextEntry = true

            placeholder = "Password"
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AuthViewController: UIViewController {
    private let authController: AuthController

    private var containerStackView: UIStackView!

    private var loginTextField: AuthTextField!

    private var passwordTextField: AuthTextField!

    private var signInButton: UIButton!

    private var signUpButton: UIButton!

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
        loginTextField.delegate = self
        containerStackView.addArrangedSubview(loginTextField)
        containerStackView.setCustomSpacing(24, after: loginTextField)

        passwordTextField = AuthTextField(type: .password)
        passwordTextField.delegate = self
        containerStackView.addArrangedSubview(passwordTextField)
        containerStackView.setCustomSpacing(28, after: passwordTextField)

        signInButton = UIButton(type: .custom)
        signInButton.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        signInButton.backgroundColor = .systemBlue
        signInButton.layer.cornerRadius = 10
        signInButton.layer.cornerCurve = .continuous
        containerStackView.addArrangedSubview(signInButton)
        containerStackView.setCustomSpacing(6, after: signInButton)

        signUpButton = UIButton(type: .custom)
        signUpButton.addTarget(self, action: #selector(signUpButtonPressed), for: .touchUpInside)
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        signUpButton.setTitleColor(.systemBlue, for: .normal)
        containerStackView.addArrangedSubview(signUpButton)
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
            make.width.equalTo(280)
            make.height.equalTo(36)
        }

        passwordTextField.snp.makeConstraints { make in
            make.width.equalTo(280)
            make.height.equalTo(36)
        }

        signInButton.snp.makeConstraints { make in
            make.width.equalTo(280)
            make.height.equalTo(47)
        }

        signUpButton.snp.makeConstraints { make in
            make.width.equalTo(47)
            make.height.equalTo(28)
        }
    }

    private func handleError(_ error: Error) {
        Logger.general.error("\(error.localizedDescription)")

        var alertView: AlertViewProtocol?

        switch error {
        case AuthControllerError.invalidEmail:
            alertView = AlertAppleMusic17View(title: "Invalid credantials", subtitle: nil, icon: .error)
        case AuthControllerError.wrongPassword:
            alertView = AlertAppleMusic17View(title: "Invalid credantials", subtitle: nil, icon: .error)
        case AuthControllerError.tooManyRequests:
            alertView = AlertAppleMusic17View(title: "Too many attempts", subtitle: nil, icon: .error)
        case AuthControllerError.invalidLoginCredentials:
            alertView = AlertAppleMusic17View(title: "Invalid credantials", subtitle: nil, icon: .error)
        default: break
        }

        alertView?.present(on: view, completion: nil)
    }

    private func signIn() {
        if let login = loginTextField.text, !login.isEmpty,
           let password = passwordTextField.text, !password.isEmpty {
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
        if let login = loginTextField.text,
           let password = passwordTextField.text {
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
        loginTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        Logger.general.log("\(#function)")
        signIn()
    }

    @objc private func signUpButtonPressed() {
        loginTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        Logger.general.log("\(#function)")
        signUp()
    }

    @objc private func tapGestureRecognizerAction() {
        if loginTextField.isFirstResponder {
            loginTextField.resignFirstResponder()
        } else if passwordTextField.isFirstResponder {
            passwordTextField.resignFirstResponder()
        }
    }
}

// MARK: - UITextFieldDelegate

extension AuthViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as? NSString else {
            return true
        }

        let resultingText = text.replacingCharacters(in: range, with: string)

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case loginTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            passwordTextField.resignFirstResponder()
        default:
            break
        }

        return true
    }
}

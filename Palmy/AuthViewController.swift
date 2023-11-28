import UIKit
import OSLog
import SnapKit
import AlertKit
import FirebaseAuth

enum AuthTextFieldType {
    case login
    case password
}

class AuthTextField: UIView {
    var title: String {
        didSet {
            titleLabel.text = title
        }
    }

    var type: AuthTextFieldType

    weak var delegate: UITextFieldDelegate? {
        didSet {
            textField.delegate = delegate
        }
    }

    var titleLabel: UILabel!

    var textField: UITextField!

    var backgroundView: UIView!

    init(type: AuthTextFieldType) {
        self.type = type

        title = ""
        delegate = nil

        super.init(frame: .zero)

        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = UIColor(cgColor: CGColor(red: 93/255, green: 93/255, blue: 93/255, alpha: 1))
        addSubview(titleLabel)

        textField = UITextField()
        textField.textColor = UIColor(cgColor: CGColor(red: 212/255, green: 212/255, blue: 212/255, alpha: 1))

        switch type {
        case .login:
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            textField.keyboardType = .emailAddress
            textField.returnKeyType = .continue
        case .password:
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            textField.keyboardType = .default
            textField.returnKeyType = .done
        }

        let fontDescriptor = UIFont.systemFont(ofSize: 17).fontDescriptor.withDesign(.rounded)!
        textField.font = UIFont(descriptor: fontDescriptor, size: 12)
        addSubview(textField)

        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
        backgroundView.layer.cornerRadius = 7
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.masksToBounds = true
        insertSubview(backgroundView, at: 0)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(backgroundView.snp.leading).inset(7)
            make.bottom.equalTo(backgroundView.snp.top).offset(-2)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-7)
        }

        textField.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(10)
            make.centerY.equalTo(backgroundView)
        }

        backgroundView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(29)
            make.horizontalEdges.equalToSuperview()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.becomeFirstResponder()
    }
}

class AuthViewController: UIViewController {
    private let authController: AuthController

    private var containerStackView: UIStackView!

    private var loginTextField: AuthTextField!

    private var passwordTextField: AuthTextField!

    private var signInButton: UIButton!

    private var tapGestureRecognizer: UITapGestureRecognizer!

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
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))
//        view.addGestureRecognizer(tapGestureRecognizer)

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
        let alertView = AlertAppleMusic17View(title: "Error", subtitle: nil, icon: .error)
        alertView.present(on: view)

        switch error {
        case AuthControllerError.invalidEmail:
            Logger.general.error("\(error.localizedDescription)")
        case AuthControllerError.wrongPassword:
            Logger.general.error("\(error.localizedDescription)")
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

    @objc private func signInButtonPressed() {
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

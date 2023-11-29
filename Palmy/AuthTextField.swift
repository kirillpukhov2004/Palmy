import UIKit

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
            textField.autocorrectionType = .default
            textField.spellCheckingType = .default
            textField.keyboardType = .emailAddress
            textField.returnKeyType = .continue
            textField.textContentType = .username
        case .password:
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.textContentType = .password
            textField.isSecureTextEntry = true
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

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if super.hitTest(point, with: event) === self {
            return textField
        }

        return super.hitTest(point, with: event)
    }
}

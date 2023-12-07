import OSLog
import FirebaseAuth

enum AuthControllerError: Error, LocalizedError {
    case invalidLoginCredentials

    case invalidEmail

    case emailAlreadyInUse

    case weakPassword

    case wrongPassword

    case keychainError

    case tooManyRequests

    case internalError(Error)

    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidLoginCredentials:
            return "Invalid login credentials"
        case .invalidEmail:
            return "Invalid email"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .weakPassword:
            return "Weak password"
        case .wrongPassword:
            return "Wrong password"
        case .keychainError:
            return "Keycahin error"
        case .tooManyRequests:
            return "Too many requests"
        case .internalError(let error):
            return "Internal error, \(error.localizedDescription)"
        case .unknown(let error):
            return"Unknown error, \(error.localizedDescription)"
        }
    }
}

final class AuthController {
    private let auth: Auth

    weak var delegate: AuthControllerDelegate?

    var isAuthorized: Bool {
        didSet {
            delegate?.authControllerDidAuthorizationStatusChanged(self)
        }
    }

    var user: FirebaseAuth.User?

    private var authStateDidChangeListener: AuthStateDidChangeListenerHandle?

    init() {
        auth = Auth.auth()

        isAuthorized = false

        authStateDidChangeListener = auth.addStateDidChangeListener{ [weak self] _, user in
            self?.user = user

            if let _ = user {
                self?.isAuthorized = true
            }
        }
    }

    deinit {
        if let authStateDidChangeListener = authStateDidChangeListener {
            auth.removeStateDidChangeListener(authStateDidChangeListener)
        }
    }

    func signIn(withEmail email: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { authDataResult, error in
            guard let _ = authDataResult, error == nil else {
                if let error = error as? NSError {
                    switch error.code {
                    case AuthErrorCode.invalidEmail.rawValue:
                        completionHandler(AuthControllerError.invalidEmail)
                    case AuthErrorCode.wrongPassword.rawValue:
                        completionHandler(AuthControllerError.wrongPassword)
                    case AuthErrorCode.internalError.rawValue:
                        if let underLayingError = error.userInfo["NSUnderlyingError"] as? NSError,
                           let responseKey = underLayingError.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] as? Dictionary<String, Any>,
                           let message = responseKey["message"] as? String,
                           message == "INVALID_LOGIN_CREDENTIALS" {
                            completionHandler(AuthControllerError.invalidLoginCredentials)
                        } else {
                            completionHandler(AuthControllerError.internalError(error))
                        }
                    case AuthErrorCode.tooManyRequests.rawValue:
                        completionHandler(AuthControllerError.tooManyRequests)
                    default:
                        completionHandler(AuthControllerError.unknown(error))
                    }
                }

                return
            }

            completionHandler(nil)
        }
    }

    func signUp(withEmail email: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { authDataResult, error in
            guard let _ = authDataResult, error != nil else {
                if let error = error as? NSError {
                    switch error.code {
                    case AuthErrorCode.invalidEmail.rawValue:
                        completionHandler(AuthControllerError.invalidEmail)
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        completionHandler(AuthControllerError.emailAlreadyInUse)
                    case AuthErrorCode.weakPassword.rawValue:
                        completionHandler(AuthControllerError.weakPassword)
                    default:
                        completionHandler(AuthControllerError.unknown(error))
                    }
                }

                return
            }

            completionHandler(nil)
        }
    }

    func signOut() throws {
        do {
            try auth.signOut()
        } catch {
            switch (error as NSError).code {
            case AuthErrorCode.keychainError.rawValue:
                throw AuthControllerError.keychainError
            default:
                throw AuthControllerError.unknown(error)
            }
        }
    }
}

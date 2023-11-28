import OSLog
import FirebaseAuth

enum AuthControllerError: Error {
    case invalidEmail
    case invalidLoginCredentials
    case emailAlreadyInUse
    case wrongPassword
    case weakPassword
    case keychainError
    case internalError
    case unknown
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
                            completionHandler(AuthControllerError.internalError)
                        }
                    default:
                        completionHandler(AuthControllerError.unknown)
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
                        completionHandler(AuthControllerError.unknown)
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
                throw AuthControllerError.unknown
            }
        }
    }
}

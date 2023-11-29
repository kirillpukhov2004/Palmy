import FirebaseAuth

protocol AuthControllerDelegate: AnyObject {
    func authControllerDidAuthorizationStatusChanged(_ authController: AuthController)
}

import UIKit
import OSLog
import FirebaseAuth
import FirebaseFirestore
import WebRTC

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let viewController: UIViewController

        if appDelegate.authController.isAuthorized {
            viewController = MainViewController()
        } else {
            viewController = AuthViewController(authController: appDelegate.authController)
        }
        
        let navigationController = UINavigationController(rootViewController: viewController)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

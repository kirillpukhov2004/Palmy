import UIKit
import OSLog
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import WebRTC

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var authController: AuthController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        RTCInitializeSSL()

        FirebaseApp.configure()
        
        authController = AuthController()

        do {
            try authController.signOut()
        } catch {
            Logger.general.log("\(error.localizedDescription)")
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        RTCCleanupSSL()
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

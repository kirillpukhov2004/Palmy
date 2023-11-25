import UIKit
import OSLog
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import WebRTC

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var user: User?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        RTCInitializeSSL()
        RTCSetMinDebugLogLevel(.none)

        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()

        Auth.auth().signInAnonymously { authResult, error in
            guard let authResult = authResult, error == nil else {
                if let error = error {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            let firestore = Firestore.firestore()
            let usersCollectionRef = firestore.collection("users")
            let userDocumentRef = usersCollectionRef.document(authResult.user.uid)
            userDocumentRef.getDocument { [weak self] documentSnapshot, error in
                guard let documentSnapshot = documentSnapshot, error == nil else {
                    if let error = error {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    return
                }

                if documentSnapshot.exists {
                    do {
                        self?.user = try documentSnapshot.data(as: User.self)
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }
                } else {
                    self?.user = User(id: authResult.user.uid)

                    do {
                        guard let user = self?.user else { fatalError() }

                        try userDocumentRef.setData(from: user)
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }
                }
            }
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        RTCShutdownInternalTracer()
        RTCCleanupSSL()
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

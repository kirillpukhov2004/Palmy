import UIKit
import OSLog

class UserAccountRegistrationViewController: UIViewController {
    private let userAccountController: UserAccountControllerProtocol

    init(userAccountController: UserAccountControllerProtocol) {
        self.userAccountController = userAccountController

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

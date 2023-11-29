import UIKit
import OSLog

class AccountViewController: UIViewController {
    private let accountController: AccountViewController

    init(accountController: AccountViewController) {
        self.accountController = accountController

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

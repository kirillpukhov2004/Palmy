import Foundation

protocol UserAccountControllerProtocol: AnyObject {
    var delegate: UserAccountControllerDelegate? { get set }
    
    var userAccount: UserAccount? { get }
}

class UserAccountController: UserAccountControllerProtocol {
    weak var delegate: UserAccountControllerDelegate?

    var userAccount: UserAccount?

    init(userAccount: UserAccount? = nil) {
        self.userAccount = userAccount
    }


}

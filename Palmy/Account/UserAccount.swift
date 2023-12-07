import Foundation

struct UserAccount: Codable, Identifiable {
    let id: String

    var username: String
    var email: String

    var name: String
    var surname: String
    var middleName: String?
    var patronymic: String?

    init(id: String) {
        self.id = id

        let usernamesURL = Bundle.main.url(forResource: "usernames", withExtension: "json")!
        username = try! JSONDecoder().decode(Array<String>.self, from: Data(contentsOf: usernamesURL)).randomElement()!

        let emailsURL = Bundle.main.url(forResource: "emails", withExtension: "json")!
        email = try! JSONDecoder().decode(Array<String>.self, from: Data(contentsOf: emailsURL)).randomElement()!

        name = ""
        surname = ""
    }   
}

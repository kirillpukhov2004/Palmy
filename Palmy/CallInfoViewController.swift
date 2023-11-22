import UIKit
import OSLog
import AlertKit

class RoomDetailsViewController: UIViewController {
    var room: Room

    var roomIdLabel: UILabel!
    var tapGestureRecognizer: UITapGestureRecognizer!

    init(room: Room) {
        self.room = room

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        roomIdLabel = UILabel()
        roomIdLabel.font = .preferredFont(forTextStyle: .body)
        roomIdLabel.adjustsFontSizeToFitWidth = true
        roomIdLabel.isUserInteractionEnabled = true
        view.addSubview(roomIdLabel)

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer))
        roomIdLabel.addGestureRecognizer(tapGestureRecognizer)

        roomIdLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            roomIdLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            roomIdLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

//        tableView = UITableView()
//        tableView.register(CallDetailsTableViewCell.self, forCellReuseIdentifier: CallDetailsTableViewCell.identifier)
//        tableView.dataSource = self
//        view.addSubview(tableView)
//
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
//            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
    }

    override func viewDidLoad() {
        roomIdLabel.text = room.id
    }

    @objc private func handleTapGestureRecognizer() {
        UIPasteboard.general.string = room.id

        let alertView = AlertAppleMusic17View(title: "Copied", subtitle: nil, icon: .custom(UIImage(systemName: "doc.on.doc")!))
        alertView.present(on: view)
    }
}

//extension CallDetailsViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return CallDetailsTableViewField.allCases.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: CallDetailsTableViewCell.identifier, for: indexPath) as! CallDetailsTableViewCell
//
//        let field = CallDetailsTableViewField.allCases[indexPath.row]
//
//        switch field {
//        case .id:
//            var contentConfiguration = cell.defaultContentConfiguration()
//            contentConfiguration.text = call.id
//
//            cell.contentConfiguration = contentConfiguration
//        }
//
//        return cell
//    }
//}
//
//class CallDetailsTableViewCell: UITableViewCell {
//    static let identifier = "CallDetailsTableViewCell"
//}
//
//enum CallDetailsTableViewField: CaseIterable {
//    case id
//}

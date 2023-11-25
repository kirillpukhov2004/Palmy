import Combine
import WebRTC

protocol SignalingServerSession: AnyObject {
    typealias RoomID = String

    var delegate: SignalingServerSessionDelegate? { get set }

    func send(_ message: SignalingServerMessage) throws

    func createRoom(completionHandler: @escaping (Result<RoomID, Error>) -> Void)

    func joinRoom(with id: String, completionHandler: @escaping (Result<RTCSessionDescription, Error>) -> Void)

    func leaveRoom()
}

import Combine
import WebRTC

// SignalingChannel or SignalingServerChannel
protocol SignalingServerSession: AnyObject {
    var delegate: (SignalingServerSessionDelegate)? { get set }

    func send(_ message: SignalingServerMessage) throws

    func createRoom(completionHandler: @escaping (Result<Room, Error>) -> Void)

    func joinRoom(with id: String, completionHandler: @escaping (Result<(Room, RTCSessionDescription), Error>) -> Void)

    func leaveRoom()
}

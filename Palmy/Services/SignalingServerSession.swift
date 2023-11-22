import Combine
import WebRTC

// SignalingChannel or SignalingServerChannel
protocol SignalingServerSession {
    var didRecieveRemoteSessionDescription: PassthroughSubject<RTCSessionDescription, Never> { get }
    var didRecieveRemoteIceCandidate: PassthroughSubject<RTCIceCandidate, Never> { get }

    func send(_ message: SignalingServerMessage) throws

    func createRoom(completionHandler: @escaping (Result<Room, Error>) -> Void)

    func joinRoom(with id: String, completionHandler: @escaping (Result<(Room, RTCSessionDescription), Error>) -> Void)

    func leaveRoom()
}

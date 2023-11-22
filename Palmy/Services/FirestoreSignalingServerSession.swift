import Combine
import OSLog
import FirebaseFirestore
import WebRTC

enum FirestoreSignalingServerSessionError: Error {
    case userNotAuthorized
}

class FirestoreSignalingServerSession: SignalingServerSession {
    weak var delegate: SignalingServerSessionDelegate?

    let firestore: Firestore

    private(set) var callDocumentRef: DocumentReference?
    private(set) var localIceCandidatesCollectionRef: CollectionReference?
    private(set) var remoteIceCandidatesCollectionRef: CollectionReference?
    private(set) var participantsCollectionRef: CollectionReference?

    private var remoteSessionDescriptionListner: ListenerRegistration?
    private var remoteIceCandidatesListner: ListenerRegistration?

    init(firestore: Firestore) {
        self.firestore = firestore
    }

    func send(_ message: SignalingServerMessage) throws {
        switch message.type {
        case .offer, .answer:
            let sessionDescription = try JSONDecoder().decode(SessionDescription.self, from: message.data)

            try callDocumentRef?.setData(from: sessionDescription)
        case .iceCandidate:
            let iceCandidate = try JSONDecoder().decode(IceCandidate.self, from: message.data)
            
            try localIceCandidatesCollectionRef?.addDocument(from: iceCandidate)
        case .iceCandidatesRemoval:
            let iceCandidates = try JSONDecoder().decode([IceCandidate].self, from: message.data)

            print("Should remove \(iceCandidates.count) iceCandidates")
        }
    }
    
    func createRoom(completionHandler: @escaping (Result<Room, Error>) -> Void) {
        guard let user = (UIApplication.shared.delegate as! AppDelegate).user else {
            completionHandler(.failure(FirestoreSignalingServerSessionError.userNotAuthorized))

            return
        }

        let participant = Room.Participant(user: user, isHost: true, isVideoEnabled: true, isAudioEnabled: false)

        do {
            try participantsCollectionRef?.addDocument(from: participant)
        } catch {
            completionHandler(.failure(error))
        }

        let roomId = UUID().uuidString
        let room = Room(id: roomId, participants: [participant])

        callDocumentRef = firestore.collection("rooms").document(roomId)
        participantsCollectionRef = callDocumentRef!.collection("participants")
        localIceCandidatesCollectionRef = callDocumentRef!.collection("offerIceCandidates")
        remoteIceCandidatesCollectionRef = callDocumentRef!.collection("answerIceCandidates")

        setupListners(for: .offer)

        completionHandler(.success(room))
    }
    
    func joinRoom(with id: String, completionHandler: @escaping (Result<(Room, RTCSessionDescription), Error>) -> Void) {
        guard let user = (UIApplication.shared.delegate as! AppDelegate).user else {
            completionHandler(.failure(FirestoreSignalingServerSessionError.userNotAuthorized))

            return
        }

        let participant = Room.Participant(user: user, isHost: true, isVideoEnabled: true, isAudioEnabled: false)

        callDocumentRef = firestore.collection("rooms").document(id)
        participantsCollectionRef = callDocumentRef!.collection("participants")
        localIceCandidatesCollectionRef = callDocumentRef!.collection("answerIceCandidates")
        remoteIceCandidatesCollectionRef = callDocumentRef!.collection("offerIceCandidates")

        callDocumentRef?.getDocument(source: .server) { [weak self] snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                if let error = error {
                    completionHandler(.failure(error))
                }

                return
            }
            
            do {
                let sessionDescription = try snapshot.data(as: SessionDescription.self)

                self?.participantsCollectionRef?.getDocuments(source: .server) { snapshot, error in
                    guard let snapshot = snapshot, error == nil else {
                        if let error = error {
                            completionHandler(.failure(error))
                        }

                        return
                    }

                    do {
                        let participants = try snapshot.documents.map { try $0.data(as: Room.Participant.self) }

                        self?.setupListners(for: .answer)

                        let room = Room(id: id, participants: participants + [participant])
                        try self?.participantsCollectionRef?.addDocument(from: participant)

                        completionHandler(.success((room, sessionDescription.rtcSessionDescription)))
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    func leaveRoom() {
        remoteSessionDescriptionListner = nil
        remoteIceCandidatesListner = nil

        callDocumentRef = nil
        localIceCandidatesCollectionRef = nil
        remoteIceCandidatesListner = nil
        participantsCollectionRef = nil
    }

    // MARK: - Private Functions

    func setupListners(for sessionType: SDPType) {
        callDocumentRef?.addSnapshotListener { [weak self] snapshot, error in
            guard let strongSelf = self else { return }

            guard let snapshot = snapshot, error == nil else {
                if let error = error {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            do {
                let sessionDescription = try snapshot.data(as: SessionDescription.self)

                guard sessionDescription.type != sessionType else { return }

                self?.delegate?.signalingServerSession(strongSelf, didRecieve: sessionDescription.rtcSessionDescription)
            } catch {
                Logger.general.error("\(error.localizedDescription)")
            }
        }

        if sessionType == .offer {
            remoteIceCandidatesCollectionRef?.addSnapshotListener { [weak self] snapshot, error in
                guard let strongSelf = self else { return }

                guard let snapshot = snapshot, error == nil else {
                    if let error = error {
                        Logger.general.error("\(error.localizedDescription)")
                    }

                    return
                }

                snapshot.documentChanges.forEach { documentChange in
                    do {
                        switch documentChange.type {
                        case .added:
                            let iceCandidate = try documentChange.document.data(as: IceCandidate.self)

                            self?.delegate?.signalingServerSession(strongSelf, didRecieve: iceCandidate.rtcIceCandidate)
                        case .removed:
                            let iceCandidate = try documentChange.document.data(as: IceCandidate.self)

                            self?.delegate?.signalingServerSession(strongSelf, didRecieveRemoved: iceCandidate.rtcIceCandidate)
                        default:
                            return
                        }
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

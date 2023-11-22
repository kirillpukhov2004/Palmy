import Combine
import OSLog
import FirebaseFirestore
import WebRTC

enum FirestoreSignalingServerSessionError: Error {
    case userNotAuthorized
}

class FirestoreSignalingServerSession: SignalingServerSession {
    let firestore: Firestore

    private(set) var callDocumentRef: DocumentReference?
    private(set) var localIceCandidatesCollectionRef: CollectionReference?
    private(set) var remoteIceCandidatesCollectionRef: CollectionReference?
    private(set) var participantsCollectionRef: CollectionReference?

    private var cancellables = Set<AnyCancellable>()

    let didRecieveRemoteSessionDescription = PassthroughSubject<RTCSessionDescription, Never>()
    let didRecieveRemoteIceCandidate = PassthroughSubject<RTCIceCandidate, Never>()

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

        callDocumentRef?.addSnapshotListener { [weak self] snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                if let error = error {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            do {
                let sessionDescription = try snapshot.data(as: SessionDescription.self)
                
                guard sessionDescription.type == .answer else { return }

                self?.didRecieveRemoteSessionDescription.send(sessionDescription.rtcSessionDescription)
            } catch {
                Logger.general.error("\(error.localizedDescription)")
            }
        }

        remoteIceCandidatesCollectionRef?.addSnapshotListener { [weak self] snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                if let error = error {
                    Logger.general.error("\(error.localizedDescription)")
                }

                return
            }

            snapshot.documentChanges.forEach { documentChange in
                if documentChange.type == .added {
                    do {
                        let iceCandidate = try documentChange.document.data(as: IceCandidate.self)

                        self?.didRecieveRemoteIceCandidate.send(iceCandidate.rtcIceCandidate)
                    } catch {
                        Logger.general.error("\(error.localizedDescription)")
                    }
                }
            }
        }

        completionHandler(.success(room))
    }
    
    func joinRoom(with id: String, completionHandler: @escaping (Result<(Room, RTCSessionDescription), Error>) -> Void) {
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

                        self?.remoteIceCandidatesListner = self?.remoteIceCandidatesCollectionRef?.addSnapshotListener { [weak self] snapshot, error in
                            guard let snapshot = snapshot, error == nil else {
                                if let error = error {
                                    Logger.general.error("\(error.localizedDescription)")
                                }

                                return
                            }

                            snapshot.documentChanges.forEach { documentChange in
                                if documentChange.type == .added {
                                    do {
                                        let iceCandidate = try documentChange.document.data(as: IceCandidate.self)

                                        self?.didRecieveRemoteIceCandidate.send(iceCandidate.rtcIceCandidate)
                                    } catch {
                                        Logger.general.error("\(error.localizedDescription)")
                                    }
                                }
                            }
                        }

                        let room = Room(id: id, participants: participants)

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
    
//    func sendOffer(_ sessionDescription: RTCSessionDescription) throws {
//        let sessionDescription = SessionDescription(rtcSessionDescription: sessionDescription)
//
//        try offerSessionDescriptionDocumentRef?.setData(from: sessionDescription)
//    }
//
//    func sendOffer(_ iceCandidate: RTCIceCandidate) throws {
//        let iceCandidate = IceCandidate(rtcIceCandidate: iceCandidate)
//
//        try offerCandidatesCollectionRef?.addDocument(from: iceCandidate)
//    }
//
//    func sendAnswer(_ sessionDescription: RTCSessionDescription) throws {
//        let sessionDescription = SessionDescription(rtcSessionDescription: sessionDescription)
//
//        try answerSessionDescriptionsCollectionRef?.addDocument(from: sessionDescription)
//    }
//
//    func sendAnswer(_ iceCandidate: RTCIceCandidate) throws {
//        let iceCandidate = IceCandidate(rtcIceCandidate: iceCandidate)
//
//        try answerCandidatesCollectionRef?.addDocument(from: iceCandidate)
//    }

//    func setupListners() {
//        offerCandidatesListner = offerCandidatesCollectionRef?.addSnapshotListener { [weak self] querySnapshot, error in
//            guard let querySnapshot = querySnapshot, error == nil else {
//                if let error = error {
//                    Logger.general.error("\(error.localizedDescription)")
//                }
//
//                return
//            }
//
//            querySnapshot.documentChanges.forEach { documentChange in
//                if documentChange.type == .added {
//                    do {
//                        let candidate = try documentChange.document.data(as: IceCandidate.self)
//                        let rtcCandidate = candidate.rtcIceCandidate
//
//                        self?.didRecieveOfferCandidate.send(rtcCandidate)
//                    } catch {
//                        Logger.general.error("\(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//
//        remoteSessionDescriptionListner = answerSessionDescriptionsCollectionRef?.addSnapshotListener { [weak self] querySnapshot, error in
//            guard let querySnapshot = querySnapshot, error == nil else {
//                if let error = error {
//                    Logger.general.error("\(error.localizedDescription)")
//                }
//
//                return
//            }
//
//            querySnapshot.documentChanges.forEach { documentChange in
//                if documentChange.type == .added {
//                    do {
//                        let sessionDescription = try documentChange.document.data(as: SessionDescription.self)
//                        let rtcSessionDescription = sessionDescription.rtcSessionDescription
//
//                        self?.didRecieveRemoteSessionDescription.send(rtcSessionDescription)
//                    } catch {
//                        Logger.general.error("\(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//
//        remoteCandidatesListner = answerCandidatesCollectionRef?.addSnapshotListener { [unowned self] querySnapshot, error in
//            guard let querySnapshot = querySnapshot, error == nil else {
//                if let error = error {
//                    Logger.general.error("\(error.localizedDescription)")
//                }
//
//                return
//            }
//
//            querySnapshot.documentChanges.forEach { documentChange in
//                if documentChange.type == .added {
//                    do {
//                        let candidate = try documentChange.document.data(as: IceCandidate.self)
//                        let rtcCandidate = candidate.rtcIceCandidate
//
//                        didRecieveRemoteCandidate.send(rtcCandidate)
//                    } catch {
//                        Logger.general.error("\(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//    }
//
//    func invalidateListners() {
//        remoteCandidatesListner?.remove()
//        remoteSessionDescriptionListner?.remove()
//    }
}

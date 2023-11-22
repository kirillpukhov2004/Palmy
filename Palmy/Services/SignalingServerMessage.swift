import WebRTC

enum SDPType: String, Codable {
    case offer
    case prAnswer
    case answer
    case rollback

    init(rtcSdpType: RTCSdpType) {
        switch rtcSdpType {
        case .offer:
            self = .offer
        case .prAnswer:
            self = .prAnswer
        case .answer:
            self = .answer
        case .rollback:
            self = .rollback
        @unknown default:
            fatalError()
        }
    }

    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:
            return .offer
        case .answer:
            return .answer
        case .prAnswer:
            return .prAnswer
        case .rollback:
            return .rollback
        }
    }
}

struct SessionDescription: Codable {
    let type: SDPType
    let sdp: String

    init(rtcSessionDescription: RTCSessionDescription) {
        type = SDPType(rtcSdpType: rtcSessionDescription.type)
        sdp = rtcSessionDescription.sdp
    }

    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: type.rtcSdpType, sdp: sdp)
    }
}

struct IceCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?

    init(rtcIceCandidate: RTCIceCandidate) {
        sdp = rtcIceCandidate.sdp
        sdpMLineIndex = rtcIceCandidate.sdpMLineIndex
        sdpMid = rtcIceCandidate.sdpMid
    }

    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

enum SignalingServerMessageType: String, Codable {
    case offer
    case answer
    case iceCandidate
    case iceCandidatesRemoval
}

struct SignalingServerMessage: Codable {
    let type: SignalingServerMessageType
    let data: Data

    init(_ sessionDescription: RTCSessionDescription) throws {
        switch sessionDescription.type {
        case .offer:
            type = .offer
        case .answer:
            type = .answer
        default:
            fatalError()
        }

        let sessionDescription = SessionDescription(rtcSessionDescription: sessionDescription)
        data = try JSONEncoder().encode(sessionDescription)
    }

    init(_ iceCandidate: RTCIceCandidate) throws {
        type = .iceCandidate

        let iceCandidate = IceCandidate(rtcIceCandidate: iceCandidate)
        data = try JSONEncoder().encode(iceCandidate)
    }

    init(_ iceCandidates: [RTCIceCandidate]) throws {
        type = .iceCandidatesRemoval

        let iceCandidates = iceCandidates.map { IceCandidate(rtcIceCandidate: $0) }
        data = try JSONEncoder().encode(iceCandidates)
    }
}

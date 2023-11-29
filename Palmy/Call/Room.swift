struct Room: Codable {
    var id: String

    var participants: [Participant]

    struct Participant: Codable {
        var user: User

        var isHost: Bool
        var isVideoEnabled: Bool
        var isAudioEnabled: Bool
    }
}

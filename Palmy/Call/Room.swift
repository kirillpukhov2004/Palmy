struct Room: Codable {
    var id: String

    var participants: [Participant]

    struct Participant: Codable {
        var user: UserAccount

        var isHost: Bool
        var isVideoEnabled: Bool
        var isAudioEnabled: Bool
    }
}

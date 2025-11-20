import FirebaseFirestore

struct Playlist: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var trackIDs: [String]
    var coverArtURL: String?
}

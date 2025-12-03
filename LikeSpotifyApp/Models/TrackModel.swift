import FirebaseFirestore

struct Track: Identifiable, Codable {
    @DocumentID var id: String?        
    var trackName: String
    var performerName: String
    var albumName: String?
    var duration: String
    var audioURL: String
    var coverArtURL: String?
}

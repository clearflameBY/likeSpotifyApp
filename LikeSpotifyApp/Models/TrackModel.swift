import FirebaseFirestore

struct Track: Identifiable, Codable {
    @DocumentID var id: String?           // Firestore document ID
    var trackName: String
    var performerName: String
    var albumName: String?
    var duration: String
    var audioURL: String                  // Ссылка на аудиофайл
    var coverArtURL: String?              // Ссылка на картинку
}

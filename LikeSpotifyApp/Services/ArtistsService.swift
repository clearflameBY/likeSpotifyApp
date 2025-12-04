import FirebaseFirestore
import FirebaseStorage

final class ArtistsService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func getArtists(limit: Int = 5) async throws -> [Artists] {
        var query: Query = db.collection("artists")
        if limit > 0 {
            query = query.limit(to: limit)
        }
        let snapshot = try await query.getDocuments()
        var items: [Artists] = []
        for doc in snapshot.documents {
            do {
                var artist = try doc.data(as: Artists.self)
                // Разрешаем путь фото из Storage в https, если это не https
                if !artist.photo.lowercased().hasPrefix("http://") &&
                   !artist.photo.lowercased().hasPrefix("https://") {
                    let ref = storage.reference(withPath: artist.photo)
                    do {
                        let url = try await ref.downloadURL()
                        artist.photo = url.absoluteString
                    } catch {
                        print("[ArtistsService] Failed to resolve photo for \(artist.name): \(error.localizedDescription)")
                    }
                }
                items.append(artist)
            } catch {
                print("[ArtistsService] decode error for \(doc.documentID): \(error)")
            }
        }
        return items
    }
}

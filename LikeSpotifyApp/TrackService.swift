import FirebaseFirestore

final class TrackService {
    
    private let db = Firestore.firestore()
    
    func fetchAllTracks(completion: @escaping ([Track]) -> Void) {
        db.collection("tracks").getDocuments { snapshot, error in
            let docs = snapshot?.documents ?? []
            let tracks = docs.compactMap { try? $0.data(as: Track.self) }
            // We are already on @MainActor for this method/class, so call completion directly.
            completion(tracks)
        }
    }
}

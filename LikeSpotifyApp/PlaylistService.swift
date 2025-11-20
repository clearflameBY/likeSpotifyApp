import FirebaseFirestore

final class PlaylistService {
    
    private let db = Firestore.firestore()
    
    func fetchAllPlaylists(completion: @escaping ([Playlist]) -> Void) {
        db.collection("playlists").getDocuments { snapshot, error in
            let docs = snapshot?.documents ?? []
            let playlists = docs.compactMap { try? $0.data(as: Playlist.self) }
            completion(playlists)
        }
    }
}

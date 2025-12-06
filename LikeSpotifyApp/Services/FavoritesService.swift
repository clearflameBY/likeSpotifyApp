import Foundation
import FirebaseFirestore
import FirebaseStorage

struct FavoriteEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var trackID: String?
    var track: Track
    var createdAt: Date
}

final class FavoritesService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    private var collection: CollectionReference {
        db.collection("favorites")
    }

    func add(track: Track) async throws {
        var entry = FavoriteEntry(
            id: nil,
            trackID: track.id,
            track: track,
            createdAt: Date()
        )
        entry.track = try await resolveStorageURLs(for: entry.track)
        _ = try collection.addDocument(from: entry)
    }

    func remove(byTrackID trackID: String) async throws {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }

    func isFavorite(trackID: String) async throws -> Bool {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        return snapshot.documents.first != nil
    }

    func observeFavorites(onChange: @escaping ([Track]) -> Void) {
        listener?.remove()
        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("[FavoritesService] listen error: \(error?.localizedDescription ?? "unknown")")
                    onChange([])
                    return
                }
                var tracks: [Track] = []
                for doc in snapshot.documents {
                    do {
                        let entry = try doc.data(as: FavoriteEntry.self)
                        tracks.append(entry.track)
                    } catch {
                        print("[FavoritesService] decode error: \(error.localizedDescription)")
                    }
                }
                onChange(tracks)
            }
    }

    func stopObserving() {
        listener?.remove()
        listener = nil
    }

    private func resolveStorageURLs(for track: Track) async throws -> Track {
        var out = track

        if !out.audioURL.lowercased().hasPrefix("http://") && !out.audioURL.lowercased().hasPrefix("https://") {
            let ref = storage.reference(withPath: out.audioURL)
            let url = try await ref.downloadURL()
            out.audioURL = url.absoluteString
        }

        if let cover = out.coverArtURL, !cover.isEmpty,
           !cover.lowercased().hasPrefix("http://"), !cover.lowercased().hasPrefix("https://") {
            let ref = storage.reference(withPath: cover)
            let url = try await ref.downloadURL()
            out.coverArtURL = url.absoluteString
        }

        return out
    }
}

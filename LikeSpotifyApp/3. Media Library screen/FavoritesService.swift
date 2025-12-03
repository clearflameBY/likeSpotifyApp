import Foundation
import FirebaseFirestore
import FirebaseStorage

struct FavoriteEntry: Identifiable, Codable {
    @DocumentID var id: String?           // document id в favorites
    var trackID: String?                  // id оригинального трека (если есть)
    var track: Track                      // копия трека на момент добавления
    var createdAt: Date
}

final class FavoritesService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    private var collection: CollectionReference {
        db.collection("favorites")
    }

    // Добавить трек в избранное
    func add(track: Track) async throws {
        var entry = FavoriteEntry(
            id: nil,
            trackID: track.id,
            track: track,
            createdAt: Date()
        )
        // Если в track audio/cover указаны относительные пути Storage, разрешим их
        entry.track = try await resolveStorageURLs(for: entry.track)
        _ = try collection.addDocument(from: entry)
    }

    // Удалить из избранного по trackID (если хранили trackID)
    func remove(byTrackID trackID: String) async throws {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }

    // Проверить, является ли трек избранным
    func isFavorite(trackID: String) async throws -> Bool {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        return snapshot.documents.first != nil
    }

    // Подписка на все избранные треки (реальное время)
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

    // Разрешение Storage путей в HTTPS для одного трека
    private func resolveStorageURLs(for track: Track) async throws -> Track {
        var out = track

        // audio
        if !out.audioURL.lowercased().hasPrefix("http://") && !out.audioURL.lowercased().hasPrefix("https://") {
            let ref = storage.reference(withPath: out.audioURL)
            let url = try await ref.downloadURL()
            out.audioURL = url.absoluteString
        }

        // cover
        if let cover = out.coverArtURL, !cover.isEmpty,
           !cover.lowercased().hasPrefix("http://"), !cover.lowercased().hasPrefix("https://") {
            let ref = storage.reference(withPath: cover)
            let url = try await ref.downloadURL()
            out.coverArtURL = url.absoluteString
        }

        return out
    }
}

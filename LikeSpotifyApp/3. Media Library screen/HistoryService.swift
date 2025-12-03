import Foundation
import FirebaseFirestore
import FirebaseStorage

struct HistoryEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var trackID: String?
    var track: Track
    var playedAt: Date
}

final class HistoryService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    
    private var collection: CollectionReference {
        db.collection("playHistory")
    }
    
    // Записать факт прослушивания
    func logPlay(track: Track) async {
        var entry = HistoryEntry(id: nil, trackID: track.id, track: track, playedAt: Date())
        // Разрешим Storage пути, если что
        entry.track = (try? await resolveStorageURLs(for: entry.track)) ?? track
        do {
            _ = try collection.addDocument(from: entry)
        } catch {
            print("[HistoryService] logPlay error: \(error.localizedDescription)")
        }
    }
    
    // Наблюдать историю (последние сверху)
    func observeHistory(limit: Int = 50, onChange: @escaping ([Track]) -> Void) {
        listener?.remove()
        var query: Query = collection.order(by: "playedAt", descending: true)
        if limit > 0 { query = query.limit(to: limit) }
        listener = query.addSnapshotListener { snapshot, error in
            guard let snapshot else {
                print("[HistoryService] listen error: \(error?.localizedDescription ?? "unknown")")
                onChange([])
                return
            }
            var tracks: [Track] = []
            for doc in snapshot.documents {
                do {
                    let entry = try doc.data(as: HistoryEntry.self)
                    tracks.append(entry.track)
                } catch {
                    print("[HistoryService] decode error: \(error.localizedDescription)")
                }
            }
            onChange(tracks)
        }
    }
    
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Helpers
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

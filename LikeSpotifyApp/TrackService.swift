import FirebaseFirestore
import FirebaseStorage

final class TrackService {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func getAllTracks() async throws -> [Track] {
        let snapshot = try await db.collection("tracks").getDocuments()
        let tracks: [Track] = snapshot.documents.compactMap { doc in
            do {
                return try doc.data(as: Track.self)
            } catch {
                return nil
            }
        }
        // Разрешаем Storage пути в реальные HTTPS ссылки (если уже https — оставляем как есть)
        let resolved = try await resolveStorageURLs(for: tracks)
        return resolved
    }
    
    // fetch specific tracks by document IDs (batched by 10 due to Firestore 'in' limits)
    func getTracks(byIDs ids: [String]) async throws -> [Track] {
        guard !ids.isEmpty else { return [] }
        var result: [Track] = []
        let chunks = ids.chunked(into: 10)
        for chunk in chunks {
            let snapshot = try await db.collection("tracks")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let tracks: [Track] = snapshot.documents.compactMap { doc in
                do {
                    return try doc.data(as: Track.self)
                } catch {
                    return nil
                }
            }
            result.append(contentsOf: tracks)
        }
        // Сохраняем порядок как в ids
        let map = Dictionary(uniqueKeysWithValues: result.compactMap { t in (t.id ?? "", t) })
        let ordered = ids.compactMap { map[$0] }
        // Разрешаем Storage пути в реальные HTTPS ссылки
        let resolved = try await resolveStorageURLs(for: ordered)
        return resolved
    }
    
    // Новый метод: загрузить треки по названию альбома
    func getTracks(byAlbumName albumName: String) async throws -> [Track] {
        let snapshot = try await db.collection("tracks")
            .whereField("albumName", isEqualTo: albumName)
            .getDocuments()
        
        let tracks: [Track] = snapshot.documents.compactMap { doc in
            do {
                return try doc.data(as: Track.self)
            } catch {
                return nil
            }
        }
        // Разрешаем пути Storage в HTTPS ссылки
        let resolved = try await resolveStorageURLs(for: tracks)
        return resolved
    }
    
    // MARK: - Helpers
    
    // Преобразует track.audioURL и track.coverArtURL (имена в Storage) в downloadURL.absoluteString
    private func resolveStorageURLs(for tracks: [Track]) async throws -> [Track] {
        try await withThrowingTaskGroup(of: (Int, String?, String?).self) { group in
            for (index, track) in tracks.enumerated() {
                let audioPath = track.audioURL
                let coverPath = track.coverArtURL
                
                group.addTask { [storage] in
                    // audio
                    let resolvedAudio: String?
                    if audioPath.lowercased().hasPrefix("http://") || audioPath.lowercased().hasPrefix("https://") {
                        resolvedAudio = audioPath
                    } else {
                        let ref = storage.reference(withPath: audioPath)
                        do {
                            let url = try await ref.downloadURL()
                            resolvedAudio = url.absoluteString
                        } catch {
                            print("[TrackService] Failed to resolve audio Storage URL for '\(audioPath)': \(error.localizedDescription)")
                            resolvedAudio = nil
                        }
                    }
                    
                    // cover
                    var resolvedCover: String?
                    if let coverPath, !coverPath.isEmpty {
                        if coverPath.lowercased().hasPrefix("http://") || coverPath.lowercased().hasPrefix("https://") {
                            resolvedCover = coverPath
                        } else {
                            let coverRef = storage.reference(withPath: coverPath)
                            do {
                                let url = try await coverRef.downloadURL()
                                resolvedCover = url.absoluteString
                            } catch {
                                print("[TrackService] Failed to resolve cover Storage URL for '\(coverPath)': \(error.localizedDescription)")
                                resolvedCover = nil
                            }
                        }
                    } else {
                        resolvedCover = nil
                    }
                    
                    return (index, resolvedAudio, resolvedCover)
                }
            }
            
            var result = tracks
            for try await (index, resolvedAudio, resolvedCover) in group {
                if let audio = resolvedAudio {
                    result[index].audioURL = audio
                }
                if let cover = resolvedCover {
                    result[index].coverArtURL = cover
                }
            }
            return result
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        chunks.reserveCapacity((count + size - 1) / size)
        var idx = startIndex
        while idx < endIndex {
            let end = index(idx, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[idx..<end]))
            idx = end
        }
        return chunks
    }
}

import FirebaseFirestore
import FirebaseStorage

@MainActor
final class PlaylistService {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func getPlaylist(named name: String) async throws -> Playlist? {
        let snapshot = try await db.collection("playlists")
            .whereField("name", isEqualTo: name)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else {
            print("[PlaylistService] No playlist found with name '\(name)'")
            return nil
        }
        
        let rawData = doc.data()
        print("[PlaylistService] Raw playlist document data for '\(name)': \(rawData)")
        
        do {
            let playlist = try doc.data(as: Playlist.self)
            return playlist
        } catch let DecodingError.keyNotFound(key, context) {
            print("[PlaylistService][DecodingError.keyNotFound] key: \(key), context: \(context.debugDescription), codingPath: \(context.codingPath)")
            print("[PlaylistService] Offending raw data: \(rawData)")
            throw DecodingError.keyNotFound(key, context)
        } catch let DecodingError.typeMismatch(type, context) {
            print("[PlaylistService][DecodingError.typeMismatch] type: \(type), context: \(context.debugDescription), codingPath: \(context.codingPath)")
            print("[PlaylistService] Offending raw data: \(rawData)")
            throw DecodingError.typeMismatch(type, context)
        } catch let DecodingError.valueNotFound(value, context) {
            print("[PlaylistService][DecodingError.valueNotFound] value: \(value), context: \(context.debugDescription), codingPath: \(context.codingPath)")
            print("[PlaylistService] Offending raw data: \(rawData)")
            throw DecodingError.valueNotFound(value, context)
        } catch let DecodingError.dataCorrupted(context) {
            print("[PlaylistService][DecodingError.dataCorrupted] context: \(context.debugDescription), codingPath: \(context.codingPath)")
            print("[PlaylistService] Offending raw data: \(rawData)")
            throw DecodingError.dataCorrupted(context)
        } catch {
            print("[PlaylistService] Unknown decoding error: \(error.localizedDescription)")
            print("[PlaylistService] Offending raw data: \(rawData)")
            let caughtError = error
            throw caughtError
        }
    }
    
    func getTracks(for playlist: Playlist) async throws -> [Track] {
        guard !playlist.tracksIDs.isEmpty else { return [] }
        
        let chunks = playlist.tracksIDs.chunked(into: 10)
        var allTracks: [Track] = []
        
        for chunk in chunks {
            let snapshot = try await db.collection("tracks")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let tracks: [Track] = snapshot.documents.compactMap { doc in
                do {
                    return try doc.data(as: Track.self)
                } catch {
                    let raw = doc.data()
                    print("[PlaylistService] Failed to decode Track with id \(doc.documentID). Raw: \(raw), error: \(error)")
                    return nil
                }
            }
            allTracks.append(contentsOf: tracks)
        }
        
        let resolved = try await resolveStorageURLs(for: allTracks)
        return resolved
    }
    
    
    private func resolveStorageURLs(for tracks: [Track]) async throws -> [Track] {
        try await withThrowingTaskGroup(of: (Int, String?, String?).self) { group in
            for (index, track) in tracks.enumerated() {
                let audioPath = track.audioURL
                let coverPath = track.coverArtURL
                
                group.addTask { [storage] in
                    let resolvedAudio: String?
                    if audioPath.lowercased().hasPrefix("http://") || audioPath.lowercased().hasPrefix("https://") {
                        resolvedAudio = audioPath
                    } else {
                        let ref = storage.reference(withPath: audioPath)
                        do {
                            let url = try await ref.downloadURL()
                            resolvedAudio = url.absoluteString
                        } catch {
                            print("[PlaylistService] Failed to resolve audio Storage URL for '\(audioPath)': \(error.localizedDescription)")
                            resolvedAudio = nil
                        }
                    }
                    
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
                                print("[PlaylistService] Failed to resolve cover Storage URL for '\(coverPath)': \(error.localizedDescription)")
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

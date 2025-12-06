import Foundation
import FirebaseFirestore

struct DownloadEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var trackID: String
    var title: String
    var artist: String
    var album: String?
    var coverArtURL: String?
    var localPath: String        
    var createdAt: Date
}

final class OfflineDownloadService {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var collection: CollectionReference {
        db.collection("downloads")
    }
    
    private var downloadsDirectory: URL {
        let dir = try! FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let subdir = dir.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: subdir.path) {
            try? FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableSubdir = subdir
        try? mutableSubdir.setResourceValues(values)
        return subdir
    }
    
    func isDownloaded(trackID: String) async throws -> Bool {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        guard let doc = snapshot.documents.first else { return false }
        let entry = try doc.data(as: DownloadEntry.self)
        return FileManager.default.fileExists(atPath: entry.localPath)
    }
    
    func localURL(for trackID: String) async throws -> URL? {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        let entry = try doc.data(as: DownloadEntry.self)
        let url = URL(fileURLWithPath: entry.localPath)
        return FileManager.default.fileExists(atPath: entry.localPath) ? url : nil
    }
    
    func download(track: Track) async throws {
        guard let id = track.id else { throw NSError(domain: "OfflineDownloadService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Track has no id"]) }
        guard let remoteURL = URL(string: track.audioURL) else { throw NSError(domain: "OfflineDownloadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid audio URL"]) }
        
        let ext = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        let fileURL = downloadsDirectory.appendingPathComponent("\(id).\(ext)")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try await ensureIndexFor(track: track, localFileURL: fileURL)
            return
        }
        
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        try? FileManager.default.removeItem(at: fileURL)
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
        
        try await ensureIndexFor(track: track, localFileURL: fileURL)
    }
    
    func removeDownload(trackID: String) async throws {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        if let doc = snapshot.documents.first {
            let entry = try doc.data(as: DownloadEntry.self)
            try? FileManager.default.removeItem(atPath: entry.localPath)
            try await doc.reference.delete()
        }
    }
    
    func observeDownloads(onChange: @escaping ([DownloadEntry]) -> Void) {
        listener?.remove()
        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("[OfflineDownloadService] listen error: \(error?.localizedDescription ?? "unknown")")
                    onChange([])
                    return
                }
                var entries: [DownloadEntry] = []
                for doc in snapshot.documents {
                    do {
                        let entry = try doc.data(as: DownloadEntry.self)
                        if FileManager.default.fileExists(atPath: entry.localPath) {
                            entries.append(entry)
                        } else {
                            doc.reference.delete()
                        }
                    } catch {
                        print("[OfflineDownloadService] decode error: \(error.localizedDescription)")
                    }
                }
                onChange(entries)
            }
    }
    
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Helpers
    private func ensureIndexFor(track: Track, localFileURL: URL) async throws {
        guard let id = track.id else { return }
        let snapshot = try await collection.whereField("trackID", isEqualTo: id).limit(to: 1).getDocuments()
        if let doc = snapshot.documents.first {
            try await doc.reference.updateData([
                "localPath": localFileURL.path,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } else {
            let entry = DownloadEntry(
                id: nil,
                trackID: id,
                title: track.trackName,
                artist: track.performerName,
                album: track.albumName,
                coverArtURL: track.coverArtURL,
                localPath: localFileURL.path,
                createdAt: Date()
            )
            _ = try collection.addDocument(from: entry)
        }
    }
}

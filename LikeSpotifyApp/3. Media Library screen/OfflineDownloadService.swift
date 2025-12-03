import Foundation
import FirebaseFirestore

struct DownloadEntry: Identifiable, Codable {
    @DocumentID var id: String?  // document id в downloads
    var trackID: String          // id трека
    var title: String            // track.trackName (для быстрого отображения)
    var artist: String           // track.performerName
    var album: String?           // track.albumName
    var coverArtURL: String?     // внешний URL обложки (для UI)
    var localPath: String        // абсолютный путь к локальному файлу
    var createdAt: Date
}

final class OfflineDownloadService {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var collection: CollectionReference {
        db.collection("downloads")
    }
    
    // Папка для аудио
    private var downloadsDirectory: URL {
        let dir = try! FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let subdir = dir.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: subdir.path) {
            try? FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        }
        // Исключим из бэкапа iCloud
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableSubdir = subdir
        try? mutableSubdir.setResourceValues(values)
        return subdir
    }
    
    // Проверить, скачан ли трек
    func isDownloaded(trackID: String) async throws -> Bool {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        guard let doc = snapshot.documents.first else { return false }
        let entry = try doc.data(as: DownloadEntry.self)
        return FileManager.default.fileExists(atPath: entry.localPath)
    }
    
    // Вернуть локальный URL, если скачан
    func localURL(for trackID: String) async throws -> URL? {
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        let entry = try doc.data(as: DownloadEntry.self)
        let url = URL(fileURLWithPath: entry.localPath)
        return FileManager.default.fileExists(atPath: entry.localPath) ? url : nil
    }
    
    // Скачать трек
    func download(track: Track) async throws {
        guard let id = track.id else { throw NSError(domain: "OfflineDownloadService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Track has no id"]) }
        guard let remoteURL = URL(string: track.audioURL) else { throw NSError(domain: "OfflineDownloadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid audio URL"]) }
        
        // Определяем имя файла
        let ext = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        let fileURL = downloadsDirectory.appendingPathComponent("\(id).\(ext)")
        
        // Если уже есть — ничего не делаем
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Убедимся, что индекс есть
            try await ensureIndexFor(track: track, localFileURL: fileURL)
            return
        }
        
        // Скачивание
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        // Перемещаем в постоянное место
        try? FileManager.default.removeItem(at: fileURL)
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
        
        // Создаём/обновляем индекс в Firestore
        try await ensureIndexFor(track: track, localFileURL: fileURL)
    }
    
    // Удалить локально + из индекса
    func removeDownload(trackID: String) async throws {
        // Найти запись
        let snapshot = try await collection.whereField("trackID", isEqualTo: trackID).limit(to: 1).getDocuments()
        if let doc = snapshot.documents.first {
            let entry = try doc.data(as: DownloadEntry.self)
            // Удалить файл
            try? FileManager.default.removeItem(atPath: entry.localPath)
            // Удалить индекс
            try await doc.reference.delete()
        }
    }
    
    // Подписка на все скачанные треки (реальное время)
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
                        // Отфильтровываем записи, где файла уже нет
                        if FileManager.default.fileExists(atPath: entry.localPath) {
                            entries.append(entry)
                        } else {
                            // Авто-очистка “битых” записей
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
            // Обновим путь (на случай переустановки)
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

import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var soundtracks: Playlist?
    
    @Published var historyTracks: [Track] = []
    @Published var favoriteTracks: [Track] = []
    @Published var downloads: [DownloadEntry] = []
    
    // Эти сервисы приватные и управляются только ViewModel
    private let historyService = HistoryService()
    private let favoritesService = FavoritesService()
    private let downloadService = OfflineDownloadService()
    private let playlistService = PlaylistService()
    
    func startObserving() {
        favoritesService.observeFavorites { [weak self] tracks in
            Task { @MainActor in self?.favoriteTracks = tracks }
        }
        downloadService.observeDownloads { [weak self] entries in
            Task { @MainActor in self?.downloads = entries }
        }
        historyService.observeHistory(limit: 50) { [weak self] tracks in
            Task { @MainActor in self?.historyTracks = tracks }
        }
    }
    
    func stopObserving() {
        favoritesService.stopObserving()
        downloadService.stopObserving()
        historyService.stopObserving()
    }
    
    func removeDownload(trackID: String) async {
        try? await downloadService.removeDownload(trackID: trackID)
    }
    
    func loadSoundtracks() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.soundtracks = try await playlistService.getPlaylist(named: "Soundtracks")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func index(of track: Track, in list: [Track]) -> Int? {
        if let id = track.id {
            return list.firstIndex(where: { $0.id == id })
        }
        return list.firstIndex(where: { $0.trackName == track.trackName && $0.performerName == track.performerName })
    }
}

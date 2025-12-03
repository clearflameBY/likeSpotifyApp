import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var newReleases: [Playlist] = []
    @Published var newReleaseTracks: [Track] = []
    
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [Track] = []
    
    @Published var recentlyPlayed: [Track] = []
    private let historyService = HistoryService()
    
    // Recommended genres shown on Home
    @Published var recommendedGenres: [Genre] = [.soundtrack, .heavyMetal, .alternativeRock]
    
    private let trackService = TrackService()

    func fetchTracks() {
        Task {
            do {
                let fetched = try await trackService.getAllTracks()
                self.tracks = fetched
            } catch {
                print("Failed to fetch tracks: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchNewReleases() {
        Task { @MainActor in
            self.newReleases = []
        }
    }
    
    func fetchNewReleaseTracks(ids: [String]) {
        Task {
            do {
                let fetched = try await trackService.getTracks(byIDs: ids)
                self.newReleaseTracks = fetched
            } catch {
                print("Failed to fetch new release tracks: \(error.localizedDescription)")
                self.newReleaseTracks = []
            }
        }
    }
    
    func searchTracks() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        isSearching = true
        
        Task {
            let lower = query.lowercased()
            let results = tracks.filter { track in
                track.trackName.lowercased().contains(lower)
                || track.performerName.lowercased().contains(lower)
                || (track.albumName?.lowercased().contains(lower) ?? false)
            }
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}

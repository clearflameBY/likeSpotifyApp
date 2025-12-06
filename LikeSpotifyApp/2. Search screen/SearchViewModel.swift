import Foundation
import Combine

final class SearchViewModel : ObservableObject {
    
    @Published var tracks: [Track] = []
    
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [Track] = []
    
    @Published var popularTracks: [Track] = []
    
    @Published var artists: [Artists] = []
    
    private let trackService = TrackService()
    private let artistsService = ArtistsService()
    
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
    
    func fetchPopularTracksByIDs(_ ids: [String]) async {
        do {
            let fetched = try await trackService.getTracks(byIDs: ids)
            await MainActor.run {
                self.popularTracks = fetched
            }
        } catch {
            print("Failed to fetch popular tracks: \(error.localizedDescription)")
            await MainActor.run { self.popularTracks = [] }
        }
    }
    
    func fetchArtists(limit: Int = 5) {
        Task {
            do {
                let fetched = try await artistsService.getArtists(limit: limit)
                await MainActor.run {
                    self.artists = fetched
                }
            } catch {
                print("Failed to fetch artists: \(error.localizedDescription)")
                await MainActor.run { self.artists = [] }
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

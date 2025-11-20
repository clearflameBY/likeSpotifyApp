import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    private let playlistService = PlaylistService()
    private let trackService = TrackService()
    
    func fetchData() {
        playlistService.fetchAllPlaylists { [weak self] playlists in
            DispatchQueue.main.async {
                self?.playlists = playlists
            }
        }
        trackService.fetchAllTracks { [weak self] tracks in
            DispatchQueue.main.async {
                self?.tracks = tracks
            }
        }
    }
}

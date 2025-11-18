import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    @Published var recentPlaylists: [Playlist] = [
        Playlist(name: "Любимые треки", description: "Треки, которые вы слушаете чаще всего", trackList: [
            Track(trackName: "Song 1", performerName: "Artist A", albumName: "Album X", duration: "3:20"),
            Track(trackName: "Song 2", performerName: "Artist B", albumName: "Album Y", duration: "2:50")
        ])
    ]

    @Published var newReleases: [Playlist] = [
        Playlist(name: "Горячие новинки", description: "Свежие релизы", trackList: [
            Track(trackName: "New Track", performerName: "Artist C", albumName: "Album Z", duration: "2:59")
        ])
    ]

    @Published var recommendedGenres: [Genre] = [
        .soundtrack, .heavyMetal, .alternativeRock
    ]

    @Published var recentTracks: [Track] = [
        Track(trackName: "Последний трек", performerName: "Artist D", albumName: "Album W", duration: "4:05")
    ]
}

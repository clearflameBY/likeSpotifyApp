import SwiftUI

struct PlaylistDetailView: View {
    let playlistName: String
    
    @State private var playlist: Playlist?
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let playlistService = PlaylistService()
    
    var body: some View {
        List {
            if let playlist {
                Section(header: Text(playlist.name)) {
                    ForEach(tracks) { track in
                        Button {
                            if URL(string: track.audioURL) != nil {
                                // Открываем плеер
                                // Можно пушить, но удобнее презентовать модально
                                selectedTrack = track
                                isPresentingPlayer = true
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.trackName)
                                        .font(.headline)
                                    Text(track.performerName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(track.duration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Загрузка...")
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if playlist == nil {
                Text("Плейлист не найден")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle(playlist?.name ?? playlistName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .sheet(isPresented: $isPresentingPlayer) {
            if let selectedTrack, let url = URL(string: selectedTrack.audioURL) {
                PlayerView(track: selectedTrack, url: url)
            }
        }
    }
    
    // MARK: - Player presentation state
    @State private var isPresentingPlayer = false
    @State private var selectedTrack: Track?
    
    // MARK: - Loading
    @MainActor
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let fetched = try await playlistService.getPlaylist(named: playlistName) {
                self.playlist = fetched
                self.tracks = try await playlistService.getTracks(for: fetched)
            } else {
                self.errorMessage = "Плейлист \(playlistName) не найден."
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

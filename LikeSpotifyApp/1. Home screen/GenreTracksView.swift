import SwiftUI

struct GenreTracksView: View {
    let title: String
    let trackIDs: [String]
    
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var isPresentingPlayer = false
    @State private var selectedTrack: Track?
    
    private let trackService = TrackService()
    
    var body: some View {
        List {
            Section(header: Text(title)) {
                ForEach(tracks) { track in
                    Button {
                        if URL(string: track.audioURL) != nil {
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
        .overlay {
            if isLoading {
                ProgressView(String(format: NSLocalizedString("Загрузка...", comment: "")))
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if tracks.isEmpty {
                Text("Треки не найдены")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .sheet(isPresented: $isPresentingPlayer) {
            PlayerView()
        }
    }
    
    @MainActor
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await trackService.getTracks(byIDs: trackIDs)
            self.tracks = fetched
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

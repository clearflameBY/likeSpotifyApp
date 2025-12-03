import SwiftUI

struct LibraryView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var soundtracks: Playlist?
    
    @State private var historyTracks: [Track] = []
    private let historyService = HistoryService()
    
    // Избранные (реальное время)
    @State private var favoriteTracks: [Track] = []
    private let favoritesService = FavoritesService()
    
    // Скачанные (реальное время)
    @State private var downloads: [DownloadEntry] = []
    private let downloadService = OfflineDownloadService()
    
    // Плеер
    @State private var isShowingPlayer = false
    @State private var selectedTrack: Track?
    @State private var selectedURL: URL?
    
    private let playlistService = PlaylistService()
    
    var body: some View {
        NavigationStack {
            List {
                // Понравившиеся
                Section(header: Text("Понравившиеся")) {
                    if favoriteTracks.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favoriteTracks, id: \.id) { track in
                            Button {
                                selectedTrack = track
                                selectedURL = URL(string: track.audioURL)
                                isShowingPlayer = selectedURL != nil
                            } label: {
                                TrackChartRow(track: track)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Скачанные для офлайн
                Section(header: Text("Скачанные для офлайн")) {
                    if downloads.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(downloads, id: \.id) { entry in
                            Button {
                                // Локальный файл
                                let fileURL = URL(fileURLWithPath: entry.localPath)
                                // Собираем Track для PlayerView (можно хранить и весь Track в DownloadEntry, но мы сохранили метаданные)
                                let t = Track(
                                    id: entry.trackID,
                                    trackName: entry.title,
                                    performerName: entry.artist,
                                    albumName: entry.album,
                                    duration: "--:--",
                                    audioURL: fileURL.absoluteString,
                                    coverArtURL: entry.coverArtURL
                                )
                                selectedTrack = t
                                selectedURL = fileURL
                                isShowingPlayer = true
                            } label: {
                                // Переиспользуем TrackChartRow, собрав временный Track (для UI)
                                let t = Track(
                                    id: entry.trackID,
                                    trackName: entry.title,
                                    performerName: entry.artist,
                                    albumName: entry.album,
                                    duration: "--:--",
                                    audioURL: entry.localPath,
                                    coverArtURL: entry.coverArtURL
                                )
                                TrackChartRow(track: t)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { try? await downloadService.removeDownload(trackID: entry.trackID) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Мои плейлисты (как было)
                Section(header: Text("Мои плейлисты")) {
                    if let soundtracks {
                        NavigationLink {
                            PlaylistDetailView(playlistName: soundtracks.name)
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.25))
                                    .frame(width: 54, height: 54)
                                    .overlay(
                                        Image(systemName: "music.note.list")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.blue)
                                    )
                                VStack(alignment: .leading) {
                                    Text(soundtracks.name)
                                        .font(.headline)
                                    Text("\(soundtracks.tracksIDs.count) треков")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    } else if isLoading {
                        HStack {
                            ProgressView()
                            Text("Загрузка плейлиста…")
                        }
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else {
                        Text("Плейлист не найден")
                            .foregroundColor(.secondary)
                    }
                }
                
                // История прослушиваний
                Section(header: Text("История прослушивания")) {
                    ForEach(historyTracks, id: \.trackName) { track in
                        TrackChartRow(track: track)
                    }
                }
            }
            .navigationTitle("Медиатека")
            .task {
                await loadSoundtracks()
            }
            .onAppear {
                favoritesService.observeFavorites { tracks in
                    DispatchQueue.main.async { self.favoriteTracks = tracks }
                }
                downloadService.observeDownloads { entries in
                    DispatchQueue.main.async { self.downloads = entries }
                }
                historyService.observeHistory(limit: 50) { tracks in
                  DispatchQueue.main.async { self.historyTracks = tracks }

                }
            }
            .onDisappear {
                favoritesService.stopObserving()
                downloadService.stopObserving()
                historyService.stopObserving()
            }
            .sheet(isPresented: $isShowingPlayer) {
                if let track = selectedTrack, let url = selectedURL {
                    PlayerView(track: track, url: url)
                }
            }
        }
    }
    
    @MainActor
    private func loadSoundtracks() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.soundtracks = try await playlistService.getPlaylist(named: "Soundtracks")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LibraryView()
}

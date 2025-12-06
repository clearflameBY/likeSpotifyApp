import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var soundtracks: Playlist?
    
    @State private var historyTracks: [Track] = []
    private let historyService = HistoryService()
    
    @State private var favoriteTracks: [Track] = []
    private let favoritesService = FavoritesService()
    
    @State private var downloads: [DownloadEntry] = []
    private let downloadService = OfflineDownloadService()
    
    @State private var isShowingPlayer = false
    @State private var selectedTrack: Track?
    @State private var selectedURL: URL?
    
    private let playlistService = PlaylistService()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Понравившиеся")) {
                    if favoriteTracks.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favoriteTracks, id: \.id) { track in
                            Button {
                                let list = favoriteTracks
                                let idx = index(of: track, in: list)
                                if let idx { playerVM.setQueue(list, startAt: idx) }
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
                
                Section(header: Text("Скачанные для офлайн")) {
                    if downloads.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(downloads, id: \.id) { entry in
                            Button {
                                let list: [Track] = downloads.map { e in
                                    let fileURL = URL(fileURLWithPath: e.localPath)
                                    return Track(
                                        id: e.trackID,
                                        trackName: e.title,
                                        performerName: e.artist,
                                        albumName: e.album,
                                        duration: "--:--",
                                        audioURL: fileURL.absoluteString,
                                        coverArtURL: e.coverArtURL
                                    )
                                }
                                let current = Track(
                                    id: entry.trackID,
                                    trackName: entry.title,
                                    performerName: entry.artist,
                                    albumName: entry.album,
                                    duration: "--:--",
                                    audioURL: URL(fileURLWithPath: entry.localPath).absoluteString,
                                    coverArtURL: entry.coverArtURL
                                )
                                let idx = index(of: current, in: list)
                                if let idx { playerVM.setQueue(list, startAt: idx) }
                                
                                selectedTrack = current
                                selectedURL = URL(fileURLWithPath: entry.localPath)
                                isShowingPlayer = true
                            } label: {
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
                
                Section(header: Text("История прослушивания")) {
                    ForEach(historyTracks, id: \.trackName) { track in
                        Button {
                            let list = historyTracks
                            let idx = index(of: track, in: list)
                            if let idx { playerVM.setQueue(list, startAt: idx) }
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
    
    private func index(of track: Track, in list: [Track]) -> Int? {
        if let id = track.id {
            return list.firstIndex(where: { $0.id == id })
        }
        return list.firstIndex(where: { $0.trackName == track.trackName && $0.performerName == track.performerName })
    }
}

#Preview {
    LibraryView()
}

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @StateObject private var viewModel = LibraryViewModel()
    
    @State private var isShowingPlayer = false
    @State private var selectedTrack: Track?
    @State private var selectedURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Понравившиеся")) {
                    if viewModel.favoriteTracks.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.favoriteTracks, id: \.id) { track in
                            Button {
                                let list = viewModel.favoriteTracks
                                let idx = viewModel.index(of: track, in: list)
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
                    if viewModel.downloads.isEmpty {
                        Text("Пока пусто")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.downloads, id: \.id) { entry in
                            Button {
                                let list: [Track] = viewModel.downloads.map { e in
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
                                let idx = viewModel.index(of: current, in: list)
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
                                    Task { await viewModel.removeDownload(trackID: entry.trackID) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Мои плейлисты")) {
                    if let soundtracks = viewModel.soundtracks {
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
                    } else if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text(String(format: NSLocalizedString("Загрузка плейлиста…", comment: "")))
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else {
                        Text("Плейлист не найден")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("История прослушивания")) {
                    ForEach(viewModel.historyTracks, id: \.trackName) { track in
                        Button {
                            let list = viewModel.historyTracks
                            let idx = viewModel.index(of: track, in: list)
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
                await viewModel.loadSoundtracks()
            }
            .onAppear {
                viewModel.startObserving()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
            .sheet(isPresented: $isShowingPlayer) {
                if let track = selectedTrack, let url = selectedURL {
                    PlayerView(track: track, url: url)
                }
            }
        }
    }
}

#Preview {
    LibraryView()
}

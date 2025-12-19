import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedTrack: Track?
    @State private var isShowingPlayer = false
    
    let genres = ["Поп", "Рок", "Хип-хоп", "Электроника", "Джаз", "Классика"]
    let newArtists = ["Olivia Rodrigo", "Doja Cat", "Glass Animals", "Lil Nas X"]
    
    
    private let newAlbums: [AlbumItem] = [
        AlbumItem(
            title: "Velour",
            coverURL: "https://firebasestorage.googleapis.com/v0/b/akaspotifyapp.firebasestorage.app/o/vrtei_wjrec_velour_cover.webp?alt=media&token=7e9e3c23-06b2-460d-a8c6-a5b06386ef71",
            trackIDs: ["9CHF5gebGjV9ZQqs6app"]
        ),
        AlbumItem(
            title: "Rise Again",
            coverURL: "https://firebasestorage.googleapis.com/v0/b/akaspotifyapp.firebasestorage.app/o/600x600bf-60.jpg?alt=media&token=fbac5d87-7875-4010-9648-de761476e270",
            trackIDs: ["RJy9hk1CeMbnFRpOwVay"]
        ),
    ]

    @State private var pushAlbum: AlbumItem?
    @State private var isShowingAlbum = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if viewModel.isSearching {
                        ProgressView("Поиск треков...")
                            .padding()
                    }
                    if !viewModel.searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.id) { track in
                                Button {
                                    let list = viewModel.searchResults
                                    if let idx = index(of: track, in: list) {
                                        playerVM.setQueue(list, startAt: idx)
                                        selectedTrack = track
                                        isShowingPlayer = true
                                    }
                                } label: {
                                    TrackChartRow(track: track)
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding([.horizontal, .top])
                    }
                    
                    if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                        SectionHeader(title: "Жанры")
                        GenreGridForSearch(genres: genres)
                        
                        if !viewModel.popularTracks.isEmpty {
                            SectionHeader(title: "Популярные треки")
                            VStack(spacing: 12) {
                                ForEach(viewModel.popularTracks, id: \.id) { track in
                                    Button {
                                        let list = viewModel.popularTracks
                                        if let idx = index(of: track, in: list) {
                                            playerVM.setQueue(list, startAt: idx)
                                            selectedTrack = track
                                            isShowingPlayer = true
                                        }
                                    } label: {
                                        TrackChartRow(track: track)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        SectionHeader(title: "Новые альбомы")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(newAlbums, id: \.title) { album in
                                    Button {
                                        pushAlbum = album
                                        isShowingAlbum = true
                                    } label: {
                                        AlbumCard(album: album)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        SectionHeader(title: "Новые исполнители")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.artists, id: \.id) { artist in
                                    NavigationLink {
                                        ArtistDetailView(artist: artist)
                                    } label: {
                                        ArtistCardFromModel(artist: artist)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Поиск")
            .background(
                NavigationLink(
                    destination: Group {
                        if let album = pushAlbum {
                            AlbumTracksViewForSearch(
                                album: album,
                                allTracks: viewModel.tracks
                            )
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $isShowingAlbum,
                    label: { EmptyView() }
                )
            )
            .task {
                viewModel.fetchTracks()
                await viewModel.fetchPopularTracksByIDs([
                    "QjujWUfMcOhvinGbSrRz",
                    "K6SW6MuC093MjbcwtNTh",
                    "Po9MqR3SWt6PAh1DOXAk"
                ])
                viewModel.fetchArtists()
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск по артисту и названию")
            .onChange(of: viewModel.searchText) { _ in
                viewModel.searchTracks()
            }
            .sheet(isPresented: $isShowingPlayer) {
                if let track = selectedTrack, let _ = urlFromAudioString(track.audioURL) {
                    PlayerView()
                }
            }
        }
    }
    
    private func urlFromAudioString(_ s: String) -> URL? {
        if let u = URL(string: s), u.scheme != nil {
            return u
        }
        return URL(fileURLWithPath: s)
    }
    
    private func index(of track: Track, in list: [Track]) -> Int? {
        if let id = track.id {
            return list.firstIndex(where: { $0.id == id })
        }
        return list.firstIndex(where: { $0.trackName == track.trackName && $0.performerName == track.performerName })
    }
}

struct AlbumItem: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let coverURL: String?
    let trackIDs: [String]
}

struct AlbumCard: View {
    let album: AlbumItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(album.title)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let urlStr = album.coverURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.18))
            Image(systemName: "rectangle.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundColor(.purple)
        }
    }
}

struct GenreGridForSearch: View {
    let genres: [String]
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 12), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(genres, id: \.self) { genre in
                Text(genre)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

struct TrackChartRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 14) {
            cover
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.performerName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(track.duration)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var cover: some View {
        if let cover = track.coverArtURL, let url = URL(string: cover) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.22))
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
        }
    }
}

struct AlbumTracksViewForSearch: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    
    let album: AlbumItem
    let allTracks: [Track]
    
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPresentingPlayer = false
    @State private var selectedTrack: Track?
    
    private let trackService = TrackService()
    
    var body: some View {
        List {
            Section(header: header) {
                ForEach(tracks) { track in
                    Button {
                        let list = tracks
                        if let idx = index(of: track, in: list) {
                            playerVM.setQueue(list, startAt: idx)
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
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $isPresentingPlayer) {
            if let selectedTrack, let _ = urlFromAudioString(selectedTrack.audioURL) {
                PlayerView()
            }
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 12) {
            if let urlStr = album.coverURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 60, height: 60)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 60, height: 60)
                    }
                }
            }
            Text(album.title)
                .font(.headline)
        }
    }
    
    @MainActor
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            if !album.trackIDs.isEmpty {
                let fetched = try await trackService.getTracks(byIDs: album.trackIDs)
                self.tracks = fetched
            } else {
                self.tracks = allTracks.filter { ($0.albumName ?? "").caseInsensitiveCompare(album.title) == .orderedSame }
            }
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
    
    private func urlFromAudioString(_ s: String) -> URL? {
        if let u = URL(string: s), u.scheme != nil {
            return u
        }
        return URL(fileURLWithPath: s)
    }
}

struct ArtistCard: View {
    let artistName: String

    var body: some View {
        VStack {
            Circle()
                .fill(Color.green.opacity(0.22))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.green)
                )
            Text(artistName)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .bold()
            .padding(.horizontal)
    }
}

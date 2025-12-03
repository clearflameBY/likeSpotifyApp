import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedTrack: Track?
    @State private var isShowingPlayer = false
    
    // Примерные данные для остальных секций
    let genres = ["Поп", "Рок", "Хип-хоп", "Электроника", "Джаз", "Классика"]
    let newArtists = ["Olivia Rodrigo", "Doja Cat", "Glass Animals", "Lil Nas X"]
    
    // Новые альбомы (локальная конфигурация).
    // Если у вас есть точные trackIDs — заполните их, тогда загрузка пойдет через TrackService.getTracks(byIDs:).
    // Если trackIDs пустые — экран альбома отфильтрует треки по albumName среди уже загруженных viewModel.tracks.
    private let newAlbums: [AlbumItem] = [
        AlbumItem(
            title: "Грамадазнаўства",
            coverURL: nil,
            trackIDs: [] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Stressed Out (Rock)",
            coverURL: nil,
            trackIDs: [] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Paranoid",
            coverURL: "https://firebasestorage.googleapis.com/v0/b/akaspotifyapp.firebasestorage.app/o/Black_Sabbath_Paranoid_Cover_Art.png?alt=media&token=6aa9a1dd-f70e-49c9-a69f-728eab6169f5",
            trackIDs: ["LZEUTZFOZC8c1cxDKpkj"] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Psy 6 (Six Rules), Part 1",
            coverURL: "https://firebasestorage.googleapis.com/v0/b/akaspotifyapp.firebasestorage.app/o/PSYBest6P1Cover.jpg?alt=media&token=aaa597f7-e9fe-45a9-b22b-16d1e25aa970",
            trackIDs: [] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Rise Again",
            coverURL: nil,
            trackIDs: [] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Keiner kommt klar mit mir",
            coverURL: "https://firebasestorage.googleapis.com/v0/b/akaspotifyapp.firebasestorage.app/o/5ae3edb0f85ef55e6e0ef1ede813d946.1000x1000x1.png?alt=media&token=1e663884-0de6-497d-a39a-cdfeb6ea7bc7",
            trackIDs: [] // TODO: подставить ID треков
        ),
        AlbumItem(
            title: "Neue Deutsche Welle",
            coverURL: nil,
            trackIDs: [] // TODO: подставить ID треков
        )
    ]

    @State private var pushAlbum: AlbumItem?

    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Поисковая строка с автодополнением
                        if viewModel.isSearching {
                            ProgressView("Поиск треков...")
                                .padding()
                        }
                        if !viewModel.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.searchResults, id: \.id) { track in
                                    Button {
                                        selectedTrack = track
                                        isShowingPlayer = true
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
                        
                        // Основной контент только если не идёт поиск
                        if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                            // Категории жанров
                            SectionHeader(title: "Жанры")
                            GenreGridForSearch(genres: genres)
                            
                            // Популярные треки (по заданным ID, кликабельные)
                            if !viewModel.popularTracks.isEmpty {
                                SectionHeader(title: "Популярные треки")
                                VStack(spacing: 12) {
                                    ForEach(viewModel.popularTracks, id: \.id) { track in
                                        Button {
                                            selectedTrack = track
                                            isShowingPlayer = true
                                        } label: {
                                            TrackChartRow(track: track)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Новые альбомы
                            SectionHeader(title: "Новые альбомы")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(newAlbums, id: \.title) { album in
                                        Button {
                                            pushAlbum = album
                                        } label: {
                                            AlbumCard(album: album)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Новые исполнители
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
                .navigationDestination(item: $pushAlbum) { album in
                    AlbumTracksViewForSearch(
                        album: album,
                        allTracks: viewModel.tracks
                    )
                }
                .task {
                    viewModel.fetchTracks()
                    // грузим 3 конкретных трека для секции «Популярные треки»
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
                    if let track = selectedTrack, let url = URL(string: track.audioURL) {
                        PlayerView(track: track, url: url)
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

// MARK: - Album model used on Search screen
struct AlbumItem: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let coverURL: String?
    let trackIDs: [String]
}

// MARK: - AlbumCard for Search
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

// MARK: - GenreGrid

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

// MARK: - TrackChartRow

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

// MARK: - AlbumTracksViewForSearch
// Показывает треки альбома. Если есть trackIDs — грузим их через TrackService,
// иначе фильтруем по album.title среди уже загруженных allTracks.
struct AlbumTracksViewForSearch: View {
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
                ProgressView("Загрузка...")
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
            if let selectedTrack, let url = URL(string: selectedTrack.audioURL) {
                PlayerView(track: selectedTrack, url: url)
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
                // Фолбэк: фильтруем уже загруженные треки по названию альбома
                self.tracks = allTracks.filter { ($0.albumName ?? "").caseInsensitiveCompare(album.title) == .orderedSame }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ArtistCard

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

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .bold()
            .padding(.horizontal)
    }
}

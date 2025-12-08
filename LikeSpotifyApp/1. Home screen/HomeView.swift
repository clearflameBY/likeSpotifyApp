import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTrack: Track?
    @State private var isShowingPlayer = false

    @State private var isShowingGenre = false
    @State private var selectedGenre: Genre?

    @State private var historyTracks: [Track] = []
    private let historyService = HistoryService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isSearching {
                        ProgressView("Поиск треков...")
                            .padding()
                    }
                    if !viewModel.searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.id) { track in
                                Button {
                                    let list = viewModel.searchResults
                                    let idx = index(of: track, in: list)
                                    if let idx { playerVM.setQueue(list, startAt: idx) }
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
                    if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                        SectionHeaderForHomeView(title: "Снова играет")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.tracks, id: \.trackName) { track in
                                    Button {
                                        let list = viewModel.tracks
                                        let idx = index(of: track, in: list)
                                        if let idx { playerVM.setQueue(list, startAt: idx) }
                                        selectedTrack = track
                                        isShowingPlayer = true
                                    } label: {
                                        TrackCard(track: track)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        SectionHeaderForHomeView(title: "Новые релизы")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.newReleaseTracks, id: \.id) { track in
                                    Button {
                                        let list = viewModel.newReleaseTracks
                                        let idx = index(of: track, in: list)
                                        if let idx { playerVM.setQueue(list, startAt: idx) }
                                        selectedTrack = track
                                        isShowingPlayer = true
                                    } label: {
                                        TrackCard(track: track)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        SectionHeaderForHomeView(title: "Рекомендации по жанрам")
                        GenreGrid(genres: $viewModel.recommendedGenres) { genre in
                            selectedGenre = genre
                            isShowingGenre = true
                        }

                        SectionHeaderForHomeView(title: "История прослушивания")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(historyTracks, id: \.id) { track in
                                    Button {
                                        let list = historyTracks
                                        let idx = index(of: track, in: list)
                                        if let idx { playerVM.setQueue(list, startAt: idx) }
                                        selectedTrack = track
                                        isShowingPlayer = true
                                    } label: {
                                        TrackCard(track: track)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(format: NSLocalizedString("Главная", comment: "")))
            .background(
                NavigationLink(
                    destination: Group {
                        if let g = selectedGenre {
                            GenreTracksView(title: GenreGrid.displayName(for: g),
                                            trackIDs: genreIDs(for: g))
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $isShowingGenre,
                    label: { EmptyView() }
                )
            )
            .task {
                viewModel.fetchTracks()
                viewModel.fetchNewReleaseTracks(ids: [
                    "9CHF5gebGjV9ZQqs6app",
                    "oj0hmj7QSHw87HfUCwiH"
                ])
                historyService.observeHistory(limit: 20) { tracks in
                    DispatchQueue.main.async { self.historyTracks = tracks }
                }
            }
            .onDisappear {
                historyService.stopObserving()
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
        }
    }

    private func genreIDs(for genre: Genre) -> [String] {
        switch genre {
        case .soundtrack:
            return ["flTqu7xJksgIQsmdN0zz", "nzzzRbQPWAIvfmdwXjk6", "udm3uQL1KP8MxwIqqr38"]
        case .heavyMetal:
            return ["LZEUTZFOZC8c1cxDKpkj"]
        case .alternativeRock:
            return ["Gggrb7W9p4lIsWrwRPwv"]
        }
    }
    
    private func index(of track: Track, in list: [Track]) -> Int? {
        if let id = track.id {
            return list.firstIndex(where: { $0.id == id })
        }
        return list.firstIndex(where: { $0.trackName == track.trackName && $0.performerName == track.performerName })
    }
}

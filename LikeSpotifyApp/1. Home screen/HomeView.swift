import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTrack: Track?
    @State private var isShowingPlayer = false

    // Genre navigation state
    @State private var isShowingGenre = false
    @State private var selectedGenre: Genre?

    // История прослушивания
    @State private var historyTracks: [Track] = []
    private let historyService = HistoryService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                        // Снова играет
                        SectionHeaderForHomeView(title: "Снова играет")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.tracks, id: \.trackName) { track in
                                    Button {
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

                        // Новые релизы — показываем конкретные треки по ID
                        SectionHeaderForHomeView(title: "Новые релизы")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.newReleaseTracks, id: \.id) { track in
                                    Button {
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

                        // Рекомендации по жанрам
                        SectionHeaderForHomeView(title: "Рекомендации по жанрам")
                        GenreGrid(genres: $viewModel.recommendedGenres) { genre in
                            selectedGenre = genre
                            isShowingGenre = true
                        }

                        // История прослушивания (горизонтально!)
                        SectionHeaderForHomeView(title: "История прослушивания")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(historyTracks, id: \.id) { track in
                                    Button {
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

                        // (можете оставить или убрать старую секцию "Недавно прослушанные треки")
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Главная")
            .navigationDestination(isPresented: $isShowingGenre) {
                if let g = selectedGenre {
                    GenreTracksView(title: GenreGrid.displayName(for: g),
                                    trackIDs: genreIDs(for: g))
                } else {
                    EmptyView()
                }
            }
            .task {
                viewModel.fetchTracks()
                viewModel.fetchNewReleaseTracks(ids: [
                    "RJy9hk1CeMbnFRpOwVay",
                    "P6qLWu9bmjGZROttdHbC",
                    "Po9MqR3SWt6PAh1DOXAk",
                    "VVmzuI7kFpluAhi0SVqp"
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
}

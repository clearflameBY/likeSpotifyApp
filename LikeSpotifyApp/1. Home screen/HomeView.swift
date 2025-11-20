import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Поиск
                    NavigationLink(destination: SearchView()) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Поиск по всей библиотеке")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Снова играет
                    SectionHeaderForHomeView(title: "Снова играет")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
//                            ForEach($viewModel.tracks, id: \.trackName) { playlist in
//                                PlaylistCard(playlist: HomeView)
//                            }
                        }
                        .padding(.horizontal)
                    }

                    // Новые релизы
                    SectionHeaderForHomeView(title: "Новые релизы")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
//                            ForEach(viewModel.newReleases, id: \.name) { playlist in
//                                PlaylistCard(playlist: playlist)
//                            }
                        }
                        .padding(.horizontal)
                    }

                    // Рекомендации по жанрам
                    SectionHeaderForHomeView(title: "Рекомендации по жанрам")
//                    GenreGrid(genres: viewModel.recommendedGenres)

                    // Недавно прослушанные треки
                    SectionHeaderForHomeView(title: "Недавно прослушанные треки")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
//                            ForEach(viewModel.recentTracks, id: \.trackName) { track in
//                                TrackCard(track: track)
//                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

// MARK: - SectionHeader

struct SectionHeaderForHomeView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2)
            .bold()
            .padding(.horizontal)
    }
}

// MARK: - PlaylistCard

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                )
            Text(playlist.name)
                .font(.headline)
                .lineLimit(1)
 //           Text("\(playlist.trackList.count) треков")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 140)
    }
}

// MARK: - GenreGrid

struct GenreGrid: View {
    let genres: [Genre]
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(genres, id: \.rawValue) { genre in
                Text(genre.rawValue.capitalized)
                    .font(.subheadline)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - TrackCard

struct TrackCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.25))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.orange)
                )
            Text(track.trackName)
                .font(.headline)
                .lineLimit(1)
            Text(track.performerName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

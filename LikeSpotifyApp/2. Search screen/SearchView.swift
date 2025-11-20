import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchSuggestions: [String] = ["Imagine Dragons", "Metallica", "Pop", "Rock", "Drake"]
    
    // Примерные данные
    let genres = ["Поп", "Рок", "Хип-хоп", "Электроника", "Джаз", "Классика"]
    //let popularTracks = [
//        Track(trackName: "Shape of You", performerName: "Ed Sheeran", albumName: "Divide", duration: "3:53"),
//        Track(trackName: "Blinding Lights", performerName: "The Weeknd", albumName: "After Hours", duration: "3:20"),
//        Track(trackName: "Bad Guy", performerName: "Billie Eilish", albumName: "When We All Fall Asleep", duration: "3:14")
 //   ]
    let newAlbums = ["1989 (Taylor's Version)", "Certified Lover Boy", "Justice", "Random Access Memories"]
    let newArtists = ["Olivia Rodrigo", "Doja Cat", "Glass Animals", "Lil Nas X"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Поисковая строка с автодополнением
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Исполнитель, песня или альбом", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if !searchText.isEmpty {
                            // Автодополнение
                            ForEach(searchSuggestions.filter { $0.localizedCaseInsensitiveContains(searchText) }, id: \.self) { suggestion in
                                Button(action: {
                                    searchText = suggestion
                                }) {
                                    Text(suggestion)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                                .background(Color(.systemGray6))
                            }
                        }
                    }
                    
                    // Категории жанров
                    SectionHeader(title: "Жанры")
                    GenreGridForSearch(genres: genres)
                    
                    // Чарты популярных треков
                    SectionHeader(title: "Популярные треки")
                    VStack(spacing: 12) {
 //                       ForEach(popularTracks, id: \.trackName) { track in
 //                           TrackChartRow(track: track)
 //                       }
                    }
                    .padding(.horizontal)
                    
                    // Новые альбомы
                    SectionHeader(title: "Новые альбомы")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(newAlbums, id: \.self) { album in
                                AlbumCard(albumName: album)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Новые исполнители
                    SectionHeader(title: "Новые исполнители")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(newArtists, id: \.self) { artist in
                                ArtistCard(artistName: artist)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Поиск")
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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.22))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.headline)
                Text(track.performerName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(track.duration)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - AlbumCard

struct AlbumCard: View {
    let albumName: String

    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.22))
                .frame(width: 110, height: 110)
                .overlay(
                    Image(systemName: "opticaldisc")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.orange)
                )
            Text(albumName)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)
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

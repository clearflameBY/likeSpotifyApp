import SwiftUI

struct LibraryView: View {
    // TODO: заменить мок-данные на реальные из модели пользователя
    let likedTracks: [Track] = [
        Track(trackName: "Shape of You", performerName: "Ed Sheeran", albumName: "Divide", duration: "3:53"),
        Track(trackName: "Believer", performerName: "Imagine Dragons", albumName: "Evolve", duration: "3:24")
    ]
    let userPlaylists: [Playlist] = [
        Playlist(name: "Workout", description: "Энергичные треки для тренировки", trackList: []),
        Playlist(name: "Chill", description: "Спокойная музыка для отдыха", trackList: [])
    ]
    let downloadedTracks: [Track] = [
        Track(trackName: "Sunflower", performerName: "Post Malone", albumName: "Hollywood's Bleeding", duration: "2:38")
    ]
    let listeningHistory: [Track] = [
        Track(trackName: "Bad Guy", performerName: "Billie Eilish", albumName: "When We All Fall Asleep", duration: "3:14")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Лайкнутые треки
                    SectionHeader(title: "Понравившиеся")
                    VStack(spacing: 8) {
                        ForEach(likedTracks, id: \.trackName) { track in
                            TrackChartRow(track: track)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Плейлисты пользователя
                    SectionHeader(title: "Мои плейлисты")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(userPlaylists, id: \.name) { playlist in
                                PlaylistCard(playlist: playlist)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Скачанные треки
                    SectionHeader(title: "Скачанные для офлайн")
                    VStack(spacing: 8) {
                        ForEach(downloadedTracks, id: \.trackName) { track in
                            TrackChartRow(track: track)
                        }
                    }
                    .padding(.horizontal)
                    
                    // История прослушиваний
                    SectionHeader(title: "История прослушивания")
                    VStack(spacing: 8) {
                        ForEach(listeningHistory, id: \.trackName) { track in
                            TrackChartRow(track: track)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Медиатека")
        }
    }
}

// Используй существующие компоненты SectionHeader, TrackChartRow, PlaylistCard

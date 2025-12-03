import SwiftUI

struct PlayerView: View {
    let track: Track
    let url: URL
    
    @StateObject private var vm = PlayerViewModel()
    @State private var isFavorite = false
    private let favoritesService = FavoritesService()
    private let historyService = HistoryService()
    @State private var didLogPlay = false
    
    // Offline
    private let downloadService = OfflineDownloadService()
    @State private var isDownloaded = false
    @State private var isDownloading = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Обложка
            if let cover = track.coverArtURL, let coverURL = URL(string: cover) {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 220)
                            .clipped()
                            .cornerRadius(16)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .frame(width: 220, height: 220)
                .padding(.top, 40)
            } else {
                placeholder
                    .padding(.top, 40)
            }
            
            VStack(spacing: 6) {
                Text(track.trackName)
                    .font(.title2)
                    .bold()
                Text(track.performerName)
                    .foregroundColor(.secondary)
            }
            
            // Таймлайн
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { vm.currentTime },
                    set: { vm.seek(to: $0) }
                ), in: 0...(vm.duration > 0 ? vm.duration : 1))
                
                HStack {
                    Text(formatTime(vm.currentTime))
                    Spacer()
                    Text(formatTime(vm.duration))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button {
                    vm.seek(to: max(vm.currentTime - 10, 0))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title)
                }
                
                Button {
                    vm.toggle()
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                
                Button {
                    vm.seek(to: min(vm.currentTime + 10, vm.duration))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title)
                }
                
                // Сердечко (избранное)
                Button {
                    Task { await toggleFavorite() }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .red : .primary)
                }
                .accessibilityLabel(isFavorite ? "Удалить из избранного" : "Добавить в избранное")
                
                // Скачивание (офлайн)
                Button {
                    Task { await toggleDownload() }
                } label: {
                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(isDownloaded ? .blue : .primary)
                    }
                }
                .accessibilityLabel(isDownloaded ? "Удалить скачанный трек" : "Скачать трек")
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            vm.load(url: url)
            vm.play()
            Task {
                if !didLogPlay {
                    await historyService.logPlay(track: track)
                    await MainActor.run { didLogPlay = true }
                }
                await refreshFavoriteState()
                await refreshDownloadState()
            }
        }
        .onDisappear {
            vm.pause()
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.green.opacity(0.25))
            .frame(width: 220, height: 220)
            .overlay(
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.green)
            )
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let s = Int(seconds) % 60
        let m = Int(seconds) / 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - Favorites
    private func refreshFavoriteState() async {
        guard let id = track.id else {
            isFavorite = false
            return
        }
        do {
            let fav = try await favoritesService.isFavorite(trackID: id)
            await MainActor.run { self.isFavorite = fav }
        } catch {
            await MainActor.run { self.isFavorite = false }
        }
    }
    
    private func toggleFavorite() async {
        guard let id = track.id else { return }
        do {
            if isFavorite {
                try await favoritesService.remove(byTrackID: id)
                await MainActor.run { self.isFavorite = false }
            } else {
                try await favoritesService.add(track: track)
                await MainActor.run { self.isFavorite = true }
            }
        } catch {
            print("[PlayerView] favorites error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Downloads
    private func refreshDownloadState() async {
        guard let id = track.id else {
            isDownloaded = false
            return
        }
        do {
            let downloaded = try await downloadService.isDownloaded(trackID: id)
            await MainActor.run { self.isDownloaded = downloaded }
        } catch {
            await MainActor.run { self.isDownloaded = false }
        }
    }
    
    private func toggleDownload() async {
        guard let id = track.id else { return }
        do {
            if isDownloaded {
                try await downloadService.removeDownload(trackID: id)
                await MainActor.run { self.isDownloaded = false }
            } else {
                await MainActor.run { self.isDownloading = true }
                try await downloadService.download(track: track)
                await MainActor.run {
                    self.isDownloading = false
                    self.isDownloaded = true
                }
            }
        } catch {
            await MainActor.run { self.isDownloading = false }
            print("[PlayerView] download error: \(error.localizedDescription)")
        }
    }
}

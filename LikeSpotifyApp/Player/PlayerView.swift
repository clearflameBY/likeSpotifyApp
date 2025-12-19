import SwiftUI

struct PlayerView: View {
    
    @EnvironmentObject private var playerVM: PlayerViewModel
    
    @State private var isFavorite = false
    private let favoritesService = FavoritesService()
    private let historyService = HistoryService()
    @State private var didLogPlay = false
    
    private let downloadService = OfflineDownloadService()
    @State private var isDownloaded = false
    @State private var isDownloading = false
    
    var body: some View {
        VStack(spacing: 24) {
            if let coverURL = playerVM.currentCoverArtURL {
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
                Text(playerVM.currentTrack?.trackName ?? "")
                    .font(.title2)
                    .bold()
                Text(playerVM.currentTrack?.performerName ?? "")
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 28) {
                Button {
                    playerVM.toggleShuffle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title3)
                        .foregroundColor(playerVM.shuffleEnabled ? .green : .primary)
                }
                .accessibilityLabel(playerVM.shuffleEnabled ? "Отключить перемешивание" : String(format: NSLocalizedString("Включить перемешивание", comment: "")))
                
                Button {
                    playerVM.cycleRepeatMode()
                } label: {
                    Image(systemName: repeatIconName(for: playerVM.repeatMode))
                        .font(.title3)
                        .foregroundColor(playerVM.repeatMode == .off ? .primary : .green)
                }
                .accessibilityLabel("Режим повтора: \(playerVM.repeatMode.rawValue)")
            }
            
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { playerVM.currentTime },
                    set: { playerVM.seek(to: $0) }
                ), in: 0...(playerVM.duration > 0 ? playerVM.duration : 1))
                
                HStack {
                    Text(formatTime(playerVM.currentTime))
                    Spacer()
                    Text(formatTime(playerVM.duration))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button {
                    playerVM.previous()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title2)
                        .opacity(playerVM.canGoPrevious ? 1.0 : 0.4)
                }
                .disabled(!playerVM.canGoPrevious)
                
                Button {
                    playerVM.seek(to: max(playerVM.currentTime - 10, 0))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                
                Button {
                    playerVM.toggle()
                } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                
                Button {
                    playerVM.seek(to: min(playerVM.currentTime + 10, playerVM.duration))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
                
                Button {
                    playerVM.next()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title2)
                        .opacity(playerVM.canGoNext ? 1.0 : 0.4)
                }
                .disabled(!playerVM.canGoNext)
            }
            
            HStack(spacing: 24) {
                Button {
                    Task { await toggleFavorite() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                        Text(isFavorite ? "В избранном" : String(format: NSLocalizedString("В избранное", comment: "")))
                    }
                    .font(.callout)
                    .foregroundColor(isFavorite ? .red : .primary)
                }
                .accessibilityLabel(isFavorite ? "Удалить из избранного" : String(format: NSLocalizedString("Добавить в избранное", comment: "")))
                
                Button {
                    Task { await toggleDownload() }
                } label: {
                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 22, height: 22)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                            Text(isDownloaded ? "Скачано" : "Скачать")
                        }
                        .font(.callout)
                        .foregroundColor(isDownloaded ? .blue : .primary)
                    }
                }
                .accessibilityLabel(isDownloaded ? "Удалить скачанный трек" : "Скачать трек")
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            playerVM.setTrackMetadata(playerVM.currentTrack!)
            Task {
                if !didLogPlay {
                    if let current = playerVM.currentTrack {
                        if current.id != nil, current.id == playerVM.currentTrack?.id ||
                            (current.id == nil && current.trackName == playerVM.currentTrack?.trackName && current.performerName == playerVM.currentTrack?.performerName) {
                            await historyService.logPlay(track: current)
                            await MainActor.run { didLogPlay = true }
                        }
                    }
                }
                await refreshFavoriteState()
                await refreshDownloadState()
            }
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
    
    private func repeatIconName(for mode: PlayerViewModel.RepeatMode) -> String {
        switch mode {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let s = Int(seconds) % 60
        let m = Int(seconds) / 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func refreshFavoriteState() async {
        guard let id = playerVM.currentTrack?.id else {
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
        guard let id = playerVM.currentTrack?.id else { return }
        do {
            if isFavorite {
                try await favoritesService.remove(byTrackID: id)
                await MainActor.run { self.isFavorite = false }
            } else {
                try await favoritesService.add(track: playerVM.currentTrack!)
                await MainActor.run { self.isFavorite = true }
            }
        } catch {
            print("[PlayerView] favorites error: \(error.localizedDescription)")
        }
    }
    
    private func refreshDownloadState() async {
        guard let id = playerVM.currentTrack?.id else {
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
        guard let id = playerVM.currentTrack?.id  else { return }
        do {
            if isDownloaded {
                try await downloadService.removeDownload(trackID: id)
                await MainActor.run { self.isDownloaded = false }
            } else {
                await MainActor.run { self.isDownloading = true }
                try await downloadService.download(track: playerVM.currentTrack!)
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

#Preview {
    let sample = Track(id: "demo",
                       trackName: "Demo Track",
                       performerName: "Demo Artist",
                       albumName: "Demo Album",
                       duration: "03:30",
                       audioURL: "https://example.com/audio.m4a",
                       coverArtURL: nil)
    return PlayerView()
        .environmentObject(PlayerViewModel())
}

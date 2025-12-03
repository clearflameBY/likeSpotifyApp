import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    deinit {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
    }
    
    func load(url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        
        // Обновление времени
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                                      queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            if let duration = player.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func toggle() {
        isPlaying ? pause() : play()
    }
    
    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time)
    }
}

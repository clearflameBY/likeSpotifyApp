import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

@MainActor
final class PlayerViewModel: ObservableObject {

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0

    enum RepeatMode: String, CaseIterable {
        case off
        case all
        case one
    }
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off

    @Published private(set) var queue: [Track] = []
    @Published private(set) var currentIndex: Int?
    var currentTrack: Track? {
        guard let idx = currentIndex, queue.indices.contains(idx) else { return nil }
        return queue[idx]
    }

    // Новое свойство:
    @Published private(set) var currentCoverArtURL: URL?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    private var nowPlayingInfo: [String: Any] = [:]
    private var playToken: Any?
    private var pauseToken: Any?
    private var toggleToken: Any?
    private var skipForwardToken: Any?
    private var skipBackwardToken: Any?
    private var changePositionToken: Any?
    private var nextTrackToken: Any?
    private var previousTrackToken: Any?

    deinit {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        let center = MPRemoteCommandCenter.shared()
        if let playToken { center.playCommand.removeTarget(playToken) }
        if let pauseToken { center.pauseCommand.removeTarget(pauseToken) }
        if let toggleToken { center.togglePlayPauseCommand.removeTarget(toggleToken) }
        if let skipForwardToken { center.skipForwardCommand.removeTarget(skipForwardToken) }
        if let skipBackwardToken { center.skipBackwardCommand.removeTarget(skipBackwardToken) }
        if let changePositionToken { center.changePlaybackPositionCommand.removeTarget(changePositionToken) }
        if let nextTrackToken { center.nextTrackCommand.removeTarget(nextTrackToken) }
        if let previousTrackToken { center.previousTrackCommand.removeTarget(previousTrackToken) }
        NotificationCenter.default.removeObserver(self)
    }

    func load(url: URL) {
        clearObservers()
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        attachObservers(for: item, player: newPlayer)
        updateNowPlayingMetadata(initial: true)
        setupRemoteCommands()
        updateCoverArt()
    }

    func setQueue(_ tracks: [Track], startAt index: Int) {
        queue = tracks
        currentIndex = tracks.indices.contains(index) ? index : tracks.indices.first
        guard let idx = currentIndex, let url = urlForTrack(tracks[idx]) else { return }
        load(url: url)
        setTrackMetadata(tracks[idx])
        play()
    }

    func setTrackMetadata(_ track: Track) {
        updateNowPlayingMetadata(initial: true, overrideTrack: track)
        updateCoverArt(overrideTrack: track)
    }

    func play() {
        do { try AVAudioSession.sharedInstance().setActive(true) } catch { print("[AudioSession] activate error: \(error)") }
        player?.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = seconds
                self.updateNowPlayingPlaybackState()
            }
        }
    }

    func toggleShuffle() {
        shuffleEnabled.toggle()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    var canGoNext: Bool {
        if shuffleEnabled { return queue.count > 1 }
        guard let idx = currentIndex else { return false }
        return idx < queue.count - 1 || repeatMode == .all
    }

    var canGoPrevious: Bool {
        if shuffleEnabled { return queue.count > 1 }
        guard let idx = currentIndex else { return false }
        return idx > 0 || repeatMode == .all
    }

    func next() {
        if shuffleEnabled {
            let nextIndex = randomNextIndex()
            switchToIndex(nextIndex, autoPlay: true)
            return
        }
        guard let idx = currentIndex else { return }
        let nextIndex: Int
        if idx < queue.count - 1 {
            nextIndex = idx + 1
        } else if repeatMode == .all {
            nextIndex = 0
        } else {
            pause()
            return
        }
        switchToIndex(nextIndex, autoPlay: true)
    }

    func previous() {
        if shuffleEnabled {
            let nextIndex = randomNextIndex()
            switchToIndex(nextIndex, autoPlay: true)
            return
        }
        guard let idx = currentIndex else { return }
        let prevIndex: Int
        if idx > 0 {
            prevIndex = idx - 1
        } else if repeatMode == .all {
            prevIndex = queue.count - 1
        } else {
            seek(to: 0)
            return
        }
        switchToIndex(prevIndex, autoPlay: true)
    }
}

private extension PlayerViewModel {
    func clearObservers() {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    func attachObservers(for item: AVPlayerItem, player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let dur = player.currentItem?.duration.seconds, dur.isFinite {
                    self.duration = dur
                }
                self.updateNowPlayingPlaybackState()
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handleItemFinished()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    func handleItemFinished() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            play()
        case .all:
            next()
        case .off:
            if shuffleEnabled {
                let nextIndex = randomNextIndex()
                switchToIndex(nextIndex, autoPlay: true)
            } else {
                guard let idx = currentIndex, idx < queue.count - 1 else {
                    pause()
                    seek(to: 0)
                    return
                }
                switchToIndex(idx + 1, autoPlay: true)
            }
        }
    }

    func randomNextIndex() -> Int {
        guard !queue.isEmpty else { return 0 }
        guard queue.count > 1, let currentIndex else { return 0 }
        var available = Array(queue.indices)
        available.removeAll(where: { $0 == currentIndex })
        return available.randomElement() ?? currentIndex
    }

    func switchToIndex(_ index: Int, autoPlay: Bool) {
        guard queue.indices.contains(index), let url = urlForTrack(queue[index]) else { return }
        currentIndex = index
        load(url: url)
        setTrackMetadata(queue[index])
        if autoPlay { play() }
    }

    func urlForTrack(_ track: Track) -> URL? {
        if let url = URL(string: track.audioURL), url.scheme != nil {
            return url
        } else {
            return URL(fileURLWithPath: track.audioURL)
        }
    }

    // Новый метод для обновления currentCoverArtURL
    func updateCoverArt(overrideTrack: Track? = nil) {
        let t = overrideTrack ?? currentTrack
        if let urlStr = t?.coverArtURL, let url = URL(string: urlStr) {
            currentCoverArtURL = url
        } else {
            currentCoverArtURL = nil
        }
    }
}

private extension PlayerViewModel {
    func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        if let playToken { center.playCommand.removeTarget(playToken) }
        if let pauseToken { center.pauseCommand.removeTarget(pauseToken) }
        if let toggleToken { center.togglePlayPauseCommand.removeTarget(toggleToken) }
        if let skipForwardToken { center.skipForwardCommand.removeTarget(skipForwardToken) }
        if let skipBackwardToken { center.skipBackwardCommand.removeTarget(skipBackwardToken) }
        if let changePositionToken { center.changePlaybackPositionCommand.removeTarget(changePositionToken) }
        if let nextTrackToken { center.nextTrackCommand.removeTarget(nextTrackToken) }
        if let previousTrackToken { center.previousTrackCommand.removeTarget(previousTrackToken) }

        playToken = center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.play() }
            return .success
        }
        pauseToken = center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.pause() }
            return .success
        }
        toggleToken = center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.toggle() }
            return .success
        }
        skipForwardToken = center.skipForwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.seek(to: min(self.currentTime + 15, self.duration)) }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]

        skipBackwardToken = center.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.seek(to: max(self.currentTime - 15, 0)) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]

        changePositionToken = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self.seek(to: e.positionTime) }
            return .success
        }

        nextTrackToken = center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.next() }
            return .success
        }

        previousTrackToken = center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.previous() }
            return .success
        }
    }

    func updateNowPlayingMetadata(initial: Bool, overrideTrack: Track? = nil) {
        var info: [String: Any] = nowPlayingInfo
        let t = overrideTrack ?? currentTrack

        info[MPMediaItemPropertyTitle] = t?.trackName ?? "Аудио"
        info[MPMediaItemPropertyArtist] = t?.performerName ?? ""
        if let album = t?.albumName {
            info[MPMediaItemPropertyAlbumTitle] = album
        }

        if duration.isFinite, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if let urlStr = t?.coverArtURL, let url = URL(string: urlStr) {
            Task.detached(priority: .background) { [weak self] in
                guard let self else { return }
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    await MainActor.run {
                        self.nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
                    }
                }
            }
        }

        nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        if !initial { updateNowPlayingPlaybackState() }
    }

    func updateNowPlayingPlaybackState() {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if duration.isFinite, duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    @objc
    func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if options.contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }
}

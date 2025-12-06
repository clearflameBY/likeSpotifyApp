import SwiftUI
import FirebaseCore
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: AVAudioSession.Mode.default,
                                    options: [])
            try session.setActive(true)
        } catch {
            print("[AudioSession] setup error: \(error)")
        }
        
        return true
    }
}

@main
struct LikeSpotifyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var playerVM = PlayerViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(playerVM)
        }
    }
}

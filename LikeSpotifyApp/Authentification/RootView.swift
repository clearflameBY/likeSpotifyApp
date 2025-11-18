import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
            } else {
                LoginOrSignUpView()
                    .environmentObject(auth)
            }
        }
    }
}

#Preview {
    RootView()
}

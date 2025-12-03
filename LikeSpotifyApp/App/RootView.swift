import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthService()

    var body: some View {
        Group {
 //           if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
 //           } else {
 //               LoginOrSignUpView()
  //                  .environmentObject(auth)
  //          }
        }
    }
}

#Preview {
    RootView()
}

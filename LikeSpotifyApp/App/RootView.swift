import SwiftUI

struct RootView: View {
    @StateObject private var viewModel: LoginOrSignUpViewModel

    init() {
        _viewModel = StateObject(wrappedValue: LoginOrSignUpViewModel(authService: AuthService()))
    }

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                ContentView()
            } else {
                LoginOrSignUpView()
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    RootView()
}

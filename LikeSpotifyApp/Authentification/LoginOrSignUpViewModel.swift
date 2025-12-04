//import SwiftUI
//import FirebaseAuth
//import Combine
//
//@MainActor
//final class LoginOrSignUpViewModel: ObservableObject {
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    @Published var isLoggedIn = false
//    @Published var userEmail: String?
//
//    private let authService: AuthService
//
//    init(authService: AuthService) {
//        self.authService = authService
//    }
//
//    func signIn(withEmail email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            let user = try await authService.signIn(withEmail: email, password: password)
//            userEmail = user.email
//            isLoggedIn = true
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoggedIn = false
//        }
//    }
//
//    func createUser(withEmail email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            let user = try await authService.createUser(withEmail: email, password: password)
//            userEmail = user.email
//            isLoggedIn = true
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoggedIn = false
//        }
//    }
//
//    func logout() {
//        do {
//            try authService.logout()
//            isLoggedIn = false
//            userEmail = nil
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//
//    func clearError() {
//        errorMessage = nil
//    }
//}

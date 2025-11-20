import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userEmail: String?

    func signIn(withEmail email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let data = try await Auth.auth().signIn(withEmail: email, password: password)
        
        isLoggedIn = true
        userEmail = data.user.email
        errorMessage = nil
    }
    
    func createUser(withEmail email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        if !email.isEmpty && !password.isEmpty {
            isLoggedIn = true
            let data = try await Auth.auth().createUser(withEmail: email, password: password)
            userEmail = data.user.email
            print("signUp: \(data.user)")
            errorMessage = nil
        } else {
            errorMessage = "Пожалуйста, заполните все поля"
        }
    }

    func logout() {
        isLoggedIn = false
        userEmail = nil                 
    }
}

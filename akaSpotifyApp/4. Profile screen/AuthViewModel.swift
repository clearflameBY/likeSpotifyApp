import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Для примера — простой state. Можно подключить реальный бэкенд.
    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        // Замените на реальную авторизацию!
        if email.lowercased() == "ilya@mail.com" && password == "password" {
            isLoggedIn = true
            errorMessage = nil
        } else {
            errorMessage = "Неверный email или пароль"
        }
    }

    func register(email: String, password: String, username: String) async {
        isLoading = true
        defer { isLoading = false }
        // Замените на реальную регистрацию!
        if !email.isEmpty && !password.isEmpty && !username.isEmpty {
            isLoggedIn = true
            errorMessage = nil
        } else {
            errorMessage = "Пожалуйста, заполните все поля"
        }
    }

    func logout() {
        isLoggedIn = false
    }
}

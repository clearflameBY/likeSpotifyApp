import FirebaseCore
import FirebaseAuth

final class AuthService {
    func signIn(withEmail email: String, password: String) async throws -> User {
        let data = try await Auth.auth().signIn(withEmail: email, password: password)
        return data.user
    }

    func createUser(withEmail email: String, password: String) async throws -> User {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }
        let data = try await Auth.auth().createUser(withEmail: email, password: password)
        return data.user
    }

    func logout() throws {
        try Auth.auth().signOut()
    }
}

enum AuthError: LocalizedError {
    case emptyFields

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Пожалуйста, заполните все поля"
        }
    }
}

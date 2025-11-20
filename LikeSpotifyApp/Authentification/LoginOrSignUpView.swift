import SwiftUI

struct LoginOrSignUpView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "music.note")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                    .padding(.bottom, 20)
                Text(isLogin ? "Вход" : "Регистрация")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()

                VStack(spacing: 18) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .foregroundStyle(.black)
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .foregroundStyle(.black)
                }
                .foregroundColor(.white)
                .padding(.horizontal)

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        do {
                            if isLogin {
                                try await authService.signIn(withEmail: email, password: password)
                            } else {
                                try await authService.createUser(withEmail: email, password: password)
                            }
                        } catch {
                            print(error.localizedDescription) 
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(isLogin ? "Войти" : "Зарегистрироваться")
                            .bold()
                            .padding()
                        Spacer()
                    }
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty || (!isLogin && email.isEmpty))

                Button(isLogin ? "Нет аккаунта? Зарегистрируйтесь" : "Уже есть аккаунт? Войти") {
                    withAnimation { isLogin.toggle() }
                    authService.errorMessage = nil
                }
                .foregroundColor(.green)
                .font(.callout)
                Spacer()
            }
            .padding()
            .overlay(
                authService.isLoading ? ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green)) : nil
            )
        }
    }
}

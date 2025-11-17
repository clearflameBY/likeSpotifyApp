import SwiftUI

struct LoginOrSignUpView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
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
                    if !isLogin {
                        TextField("Имя пользователя", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .foregroundColor(.white)
                .padding(.horizontal)

                if let error = auth.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        if isLogin {
                            await auth.login(email: email, password: password)
                        } else {
                            await auth.register(email: email, password: password, username: username)
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
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty || (!isLogin && username.isEmpty))

                Button(isLogin ? "Нет аккаунта? Зарегистрируйтесь" : "Уже есть аккаунт? Войти") {
                    withAnimation { isLogin.toggle() }
                    auth.errorMessage = nil
                }
                .foregroundColor(.green)
                .font(.callout)

                Spacer()
            }
            .padding()
            .overlay(
                auth.isLoading ? ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green)) : nil
            )
        }
    }
}

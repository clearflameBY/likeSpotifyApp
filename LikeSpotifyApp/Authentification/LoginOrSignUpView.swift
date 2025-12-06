import SwiftUI

struct LoginOrSignUpView: View {
    @EnvironmentObject private var viewModel: LoginOrSignUpViewModel

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

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        if isLogin {
                            await viewModel.signIn(withEmail: email, password: password)
                        } else {
                            await viewModel.createUser(withEmail: email, password: password)
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
                .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)

                Button(isLogin ? "Нет аккаунта? Зарегистрируйтесь" : "Уже есть аккаунт? Войти") {
                    withAnimation { isLogin.toggle() }
                    viewModel.clearError()
                }
                .foregroundColor(.green)
                .font(.callout)
                Spacer()
            }
            .padding()
            .overlay(
                viewModel.isLoading ? ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green)) : nil
            )
        }
    }
}

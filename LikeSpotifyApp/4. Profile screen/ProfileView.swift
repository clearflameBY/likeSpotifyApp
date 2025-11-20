import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService

    let followers = 120
    let following = 45

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                        .padding(.top, 32)
                    
                    Text(authService.userEmail ?? "Нет email")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    
                    HStack(spacing: 32) {
                        VStack {
                            Text("\(followers)")
                                .font(.title2)
                                .bold()
                            Text("Подписчики")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack {
                            Text("\(following)")
                                .font(.title2)
                                .bold()
                            Text("Подписки")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                        }) {
                            HStack {
                                Image(systemName: "gearshape")
                                Text("Настройки")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                        }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("Понравившиеся треки")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.blue)
                                Text("Управление подпиской")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        Button(role: .destructive, action: {
                            authService.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Выйти")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Профиль")
        }
    }
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(format: NSLocalizedString("Главная", comment: "")), systemImage: "music.note")
                }
            
            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            
            LibraryView()
                .tabItem {
                    Label("Медиатека", systemImage: "square.stack.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LoginOrSignUpViewModel(authService: AuthService()))
}

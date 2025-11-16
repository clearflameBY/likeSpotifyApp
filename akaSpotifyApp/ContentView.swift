import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "music.note")
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
}

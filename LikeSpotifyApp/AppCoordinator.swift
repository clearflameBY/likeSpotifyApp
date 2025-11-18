import SwiftUI
import Combine

final class AppCoordinator: ObservableObject, Coordinator {
    // Можно хранить состояние навигации или общие зависимости
    @Published var isStarted = false

    func start() {
        isStarted = true
        // Здесь может быть запуск логики и настройка стартового экрана
    }

    // Пример: доступ к ViewModel (можно расширить)
    let homeViewModel = HomeViewModel()
    let searchViewModel = SearchViewModel()
    let libraryViewModel = LibraryViewModel()
    let profileViewModel = ProfileViewModel()
}

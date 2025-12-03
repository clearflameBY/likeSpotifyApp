import SwiftUI

struct GenreGrid: View {
    @Binding var genres: [Genre]
    var onSelect: (Genre) -> Void = { _ in }
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 12), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(genres, id: \.self) { genre in
                Button {
                    onSelect(genre)
                } label: {
                    Text(displayName(for: genre))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    static func displayName(for genre: Genre) -> String {
        switch genre {
        case .soundtrack: return "Саундтреки"
        case .heavyMetal: return "Хеви-метал"
        case .alternativeRock: return "Альтернативный рок"
        }
    }
    
    private func displayName(for genre: Genre) -> String {
        Self.displayName(for: genre)
    }
}

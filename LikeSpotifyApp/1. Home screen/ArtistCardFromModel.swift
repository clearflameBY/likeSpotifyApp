import SwiftUI

struct ArtistCardFromModel: View {
    let artist: Artists
    
    var body: some View {
        VStack {
            artistPhoto
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            Text(artist.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
    
    @ViewBuilder
    private var artistPhoto: some View {
        if let url = URL(string: artist.photo) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.green.opacity(0.22))
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.green)
        }
    }
}

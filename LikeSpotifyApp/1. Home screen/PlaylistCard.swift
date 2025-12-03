import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(playlist.name)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
            if let desc = playlist.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let cover = playlist.coverArtURL, let url = URL(string: cover) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.18))
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.purple)
        }
    }
}

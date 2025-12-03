import SwiftUI

struct TrackCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(track.trackName)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
            Text(track.performerName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let cover = track.coverArtURL, let url = URL(string: cover) {
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
                .fill(Color.blue.opacity(0.18))
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.blue)
        }
    }
}

//import SwiftUI
//
//struct TrackChartRow: View {
//    let track: Track
//
//    var body: some View {
//        HStack(spacing: 12) {
//            // Cover image or placeholder
//            cover
//                .frame(width: 54, height: 54)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(track.trackName)
//                    .font(.subheadline)
//                    .bold()
//                    .lineLimit(1)
//                Text(track.performerName)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//            }
//
//            Spacer()
//
//            Text(track.duration)
//                .font(.caption2)
//                .foregroundColor(.secondary)
//        }
//    }
//
//    @ViewBuilder
//    private var cover: some View {
//        if let cover = track.coverArtURL, let url = URL(string: cover) {
//            AsyncImage(url: url) { phase in
//                switch phase {
//                case .empty:
//                    placeholder
//                case .success(let image):
//                    image.resizable().scaledToFill()
//                case .failure:
//                    placeholder
//                @unknown default:
//                    placeholder
//                }
//            }
//        } else {
//            placeholder
//        }
//    }
//
//    private var placeholder: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 8)
//                .fill(Color.blue.opacity(0.18))
//            Image(systemName: "music.note")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 20, height: 20)
//                .foregroundColor(.blue)
//        }
//    }
//}

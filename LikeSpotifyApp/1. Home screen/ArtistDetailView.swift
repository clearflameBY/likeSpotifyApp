import SwiftUI

struct ArtistDetailView: View {
    let artist: Artists
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let url = URL(string: artist.photo) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholder
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top, 24)
                } else {
                    placeholder
                        .frame(width: 200, height: 200)
                        .padding(.top, 24)
                }
                
                Text(artist.name)
                    .font(.title2)
                    .bold()
                
                Text(artist.info)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.green.opacity(0.22))
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.green)
        }
    }
}

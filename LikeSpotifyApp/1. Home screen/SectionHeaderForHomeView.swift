import SwiftUI

struct SectionHeaderForHomeView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3)
            .bold()
            .padding(.horizontal)
    }
}

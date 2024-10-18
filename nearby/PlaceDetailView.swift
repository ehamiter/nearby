import SwiftUI

struct PlaceDetailView: View {
    let place: WikipediaPlace
    @State private var imageLoadError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                if let imageURL = place.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(place.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Distance: \(Int(place.distance))m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(place.description)
                        .font(.body)
                    
                    Link("Read more on Wikipedia", destination: URL(string: "https://en.wikipedia.org/?curid=\(place.id)")!)
                        .font(.headline)
                        .padding(.top)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(place.title)
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
    }
}

import SwiftUI

struct PlaceDetailView: View {
    let place: WikipediaPlace
    @ObservedObject var distanceFormatter: DistanceFormatter
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = place.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(place.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Distance: \(distanceFormatter.format(place.distance))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            distanceFormatter.toggle()
                        }
                    
                    Text(place.longDescription)
                        .font(.body)
                    
                    Link("Read more on Wikipedia", destination: URL(string: "https://en.m.wikipedia.org/?curid=\(place.id)")!)
                        .font(.headline)
                        .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(place.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

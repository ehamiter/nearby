import SwiftUI
import CoreLocation

struct PlaceDetailView: View {
    let place: WikipediaPlace
    @ObservedObject var distanceFormatter: DistanceFormatter
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image or Letter Placeholder
                ZStack {
                    if let imageURL = place.imageURL {
                        CachedAsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                letterPlaceholder
                            @unknown default:
                                letterPlaceholder
                            }
                        }
                    } else {
                        letterPlaceholder
                    }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(15)
                
                Text(place.title)
                    .font(FontManager.rounded(size: 24, weight: .bold))
                    .foregroundColor(ColorManager.text)
                    .textCase(.lowercase)
                
                Text(distanceFormatter.format(place.distance))
                    .font(FontManager.rounded(size: 16, weight: .regular))
                    .foregroundColor(ColorManager.secondaryText)
                    .textCase(.lowercase)
                    .onTapGesture {
                        distanceFormatter.toggle()
                    }
                
                if !place.shortDescription.isEmpty {
                    Text(place.shortDescription)
                        .font(FontManager.rounded(size: 18, weight: .medium))
                        .foregroundColor(ColorManager.text)
                        .textCase(.lowercase)
                }
                
                Text(place.longDescription)
                    .font(FontManager.rounded(size: 16, weight: .regular))
                    .foregroundColor(ColorManager.text)
                    .textCase(.lowercase)
            }
            .padding()
        }
        .background(ColorManager.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: openWikipediaPage) {
                    Image(systemName: "safari")
                        .foregroundColor(ColorManager.text)
                }
            }
        }
    }
    
    var letterPlaceholder: some View {
        ZStack {
            ColorManager.placeholderBackground
            Text(place.firstLetter)
                .font(FontManager.rounded(size: 100, weight: .bold))
                .foregroundColor(ColorManager.placeholderText)
                .textCase(.lowercase)
        }
    }
    
    func openWikipediaPage() {
        let encodedTitle = place.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        if let url = URL(string: "https://en.m.wikipedia.org/wiki/\(encodedTitle)") {
            UIApplication.shared.open(url)
        }
    }
}

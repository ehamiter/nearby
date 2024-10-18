import SwiftUI
import CoreLocation

struct WikipediaPlace: Identifiable {
    let id: Int
    let title: String
    var shortDescription: String = ""
    var longDescription: String = ""
    let distance: Double
    var imageURL: URL?
    
    var firstLetter: String {
        String(title.prefix(1).uppercased())
    }
}

struct NearbyPlacesGrid: View {
    let location: CLLocationCoordinate2D
    @State private var places: [WikipediaPlace] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var distanceFormatter = DistanceFormatter()
    
    let columns = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 24), spacing: 16),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 24), spacing: 16)
    ]
    var body: some View {
        ScrollView {
            VStack {
                if isLoading {
                    ProgressView()
                    Text("loading...")
                        .font(FontManager.rounded(size: 18, weight: .regular))
                        .textCase(.lowercase)
                } else if let error = errorMessage {
                    Text("error: \(error)")
                        .font(FontManager.rounded(size: 18, weight: .regular))
                        .textCase(.lowercase)
                } else if places.isEmpty {
                    Text("no places found nearby.")
                        .font(FontManager.rounded(size: 18, weight: .regular))
                        .textCase(.lowercase)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(places) { place in
                            NavigationLink(destination: PlaceDetailView(place: place, distanceFormatter: distanceFormatter)) {
                                PlaceCard(place: place, distanceFormatter: distanceFormatter)
                            }
                            .id(place.id)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            fetchNearbyPlaces()
        }
    }
    
    func fetchNearbyPlaces() {
        isLoading = true
        errorMessage = nil
        
        WikipediaAPI.shared.fetchNearbyPlaces(location: location) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetchedPlaces):
                    self.places = fetchedPlaces
                    if fetchedPlaces.isEmpty {
                        self.errorMessage = "no places found nearby"
                    } else {
                        self.fetchPlaceDetails()
                    }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchPlaceDetails() {
        WikipediaAPI.shared.fetchPlaceDetails(places: places) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedPlaces):
                    self.places = updatedPlaces
                    for place in self.places {
                        if place.imageURL == nil {
                            self.fetchWikimediaImage(for: place)
                        }
                    }
                case .failure(let error):
                    print("Error fetching place details: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchWikimediaImage(for place: WikipediaPlace) {
        WikipediaAPI.shared.fetchWikimediaImage(for: place) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrl):
                    if let index = self.places.firstIndex(where: { $0.id == place.id }) {
                        self.places[index].imageURL = imageUrl
                    }
                case .failure(let error):
                    print("Error fetching Wikimedia image: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

struct PlaceCard: View {
    let place: WikipediaPlace
    @ObservedObject var distanceFormatter: DistanceFormatter
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
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
            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 140)
            .clipped()
            
            Text(place.title)
                .font(FontManager.rounded(size: 16, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 50)
                .textCase(.lowercase)
            
            Text(distanceFormatter.format(place.distance))
                .font(FontManager.rounded(size: 14, weight: .regular))
                .foregroundColor(ColorManager.secondaryText)
                .textCase(.lowercase)
                .onTapGesture {
                    distanceFormatter.toggle()
                }
            
            if !place.shortDescription.isEmpty {
                Text(place.shortDescription)
                    .font(FontManager.rounded(size: 12, weight: .regular))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 40)
                    .textCase(.lowercase)
            } else {
                Spacer().frame(height: 40)
            }
        }
        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 280)  // Fixed width and height for all cards
        .padding(.vertical, 8)
        .background(ColorManager.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    var letterPlaceholder: some View {
        ZStack {
            ColorManager.placeholderBackground
            Text(place.firstLetter)
                .font(FontManager.rounded(size: 60, weight: .bold))
                .foregroundColor(ColorManager.placeholderText)
                .textCase(.lowercase)
        }
    }
}

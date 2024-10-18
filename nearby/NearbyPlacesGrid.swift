import SwiftUI
import CoreLocation

struct WikipediaPlace: Identifiable {
    let id: Int
    let title: String
    var description: String = ""
    let distance: Double
    var imageURL: URL?
}

struct NearbyPlacesGrid: View {
    let location: CLLocationCoordinate2D
    @State private var places: [WikipediaPlace] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                Text("Loading...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
            } else if places.isEmpty {
                Text("No places found nearby.")
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(places) { place in
                        NavigationLink(destination: PlaceDetailView(place: place)) {
                            PlaceCard(place: place)
                                .frame(height: 220)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchNearbyPlaces()
        }
    }
    
    func fetchNearbyPlaces() {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=\(location.latitude)|\(location.longitude)&gsradius=10000&gslimit=50&format=json&maxlag=5"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("NearbyApp/1.0 (https://github.com/yourusername/NearbyApp; youremail@example.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let query = json["query"] as? [String: Any],
                   let geosearch = query["geosearch"] as? [[String: Any]] {
                    
                    let fetchedPlaces = geosearch.compactMap { place -> WikipediaPlace? in
                        guard let pageId = place["pageid"] as? Int,
                              let title = place["title"] as? String,
                              let distance = place["dist"] as? Double else {
                            return nil
                        }
                        
                        return WikipediaPlace(id: pageId, title: title, distance: distance, imageURL: nil)
                    }
                    
                    DispatchQueue.main.async {
                        self.places = fetchedPlaces
                        self.isLoading = false
                        if fetchedPlaces.isEmpty {
                            self.errorMessage = "No places found nearby"
                        } else {
                            fetchPlaceDetails()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Unable to parse results"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "JSON parsing error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchPlaceDetails() {
        let pageIds = places.map { String($0.id) }.joined(separator: "|")
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&exintro&explaintext&pageids=\(pageIds)&format=json&pithumbsize=200&maxlag=5"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.addValue("NearbyApp/1.0 (https://github.com/yourusername/NearbyApp; youremail@example.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching place details: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let query = json["query"] as? [String: Any],
                   let pages = query["pages"] as? [String: [String: Any]] {
                    
                    for (pageId, pageInfo) in pages {
                        if let index = self.places.firstIndex(where: { $0.id == Int(pageId) }) {
                            DispatchQueue.main.async {
                                self.places[index].description = pageInfo["extract"] as? String ?? ""
                                if let thumbnail = pageInfo["thumbnail"] as? [String: Any],
                                   let source = thumbnail["source"] as? String,
                                   let imageURL = URL(string: source) {
                                    self.places[index].imageURL = imageURL
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error parsing place details: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct PlaceCard: View {
    let place: WikipediaPlace
    
    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: place.imageURL) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(place.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            Text("\(Int(place.distance))m")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if !place.description.isEmpty {
                Text(place.description)
                    .font(.caption2)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(height: 48)
            } else {
                Spacer().frame(height: 48)
            }
        }
        .frame(height: 220)
        .padding(.horizontal, 4)
        .foregroundColor(.primary)
    }
}

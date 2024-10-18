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
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                Text("Loading...")
                    .font(.title3)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .font(.title3)
            } else if places.isEmpty {
                Text("No places found nearby.")
                    .font(.title3)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(places) { place in
                        NavigationLink(destination: PlaceDetailView(place: place, distanceFormatter: distanceFormatter)) {
                            PlaceCard(place: place, distanceFormatter: distanceFormatter)
                                .frame(height: 280)
                        }
                        .id(place.id)
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
        
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=\(location.latitude)|\(location.longitude)&gsradius=10000&gslimit=24&format=json&maxlag=5"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("nearby/1.0 (https://github.com/ehamiter/nearby; ehamiter@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "no data received"
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
                            self.errorMessage = "no places found nearby"
                        } else {
                            fetchPlaceDetails()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "unable to parse results"
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
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages|pageprops&exintro&explaintext&pageids=\(pageIds)&format=json&pithumbsize=200&maxlag=5"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.addValue("nearby/1.0 (https://github.com/ehamiter/nearby; ehamiter@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error fetching place details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let query = json["query"] as? [String: Any],
                   let pages = query["pages"] as? [String: [String: Any]] {
                    
                    for (pageId, pageInfo) in pages {
                        if let index = self.places.firstIndex(where: { $0.id == Int(pageId) }) {
                            DispatchQueue.main.async {
                                self.places[index].longDescription = pageInfo["extract"] as? String ?? ""
                                
                                if let pageprops = pageInfo["pageprops"] as? [String: Any],
                                   let shortDesc = pageprops["wikibase-shortdesc"] as? String {
                                    self.places[index].shortDescription = shortDesc
                                }
                                
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
    
    func fetchWikimediaImage(for place: WikipediaPlace) {
        let searchTerms = generateSearchTerms(from: place.shortDescription.isEmpty ? place.title : place.shortDescription)
        
        func tryNextSearchTerm() {
            guard !searchTerms.isEmpty else {
                DispatchQueue.main.async {
                    if let index = self.places.firstIndex(where: { $0.id == place.id }) {
                        // No image found, set to nil to trigger the letter placeholder
                        self.places[index].imageURL = nil
                        print("No suitable image found for: \(place.title)")
                    }
                }
                return
            }
            
            guard let searchTerm = searchTerms.first else {
                tryNextSearchTerm()
                return
            }
            let encodedSearch = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=\(encodedSearch)&srnamespace=6&srlimit=10&format=json"
            
            guard let url = URL(string: urlString) else {
                tryNextSearchTerm()
                return
            }
            
            var request = URLRequest(url: url)
            request.addValue("nearby/1.0 (https://github.com/ehamiter/nearby; ehamiter@gmail.com)", forHTTPHeaderField: "User-Agent")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching Wikimedia image: \(error.localizedDescription)")
                    tryNextSearchTerm()
                    return
                }
                
                guard let data = data else {
                    print("No data received from Wikimedia API")
                    tryNextSearchTerm()
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let query = json["query"] as? [String: Any],
                       let search = query["search"] as? [[String: Any]] {
                        
                        for result in search {
                            if let title = result["title"] as? String,
                               title.lowercased().hasSuffix(".jpg") || title.lowercased().hasSuffix(".png") || title.lowercased().hasSuffix(".gif") {
                                let imageUrlString = "https://commons.wikimedia.org/wiki/Special:FilePath/\(title)?width=300"
                                if let imageUrl = URL(string: imageUrlString) {
                                    DispatchQueue.main.async {
                                        if let index = self.places.firstIndex(where: { $0.id == place.id }) {
                                            self.places[index].imageURL = imageUrl
                                            print("Wikimedia image URL set: \(imageUrl)")
                                        }
                                    }
                                    return
                                }
                            }
                        }
                        tryNextSearchTerm()
                    } else {
                        print("No search results or unexpected JSON structure")
                        tryNextSearchTerm()
                    }
                } catch {
                    print("Error parsing Wikimedia search results: \(error.localizedDescription)")
                    tryNextSearchTerm()
                }
            }.resume()
        }
        
        tryNextSearchTerm()
    }
    
    func generateSearchTerms(from input: String) -> [String] {
        let words = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var terms: [String] = []
        
        for i in 0..<words.count {
            terms.append(words[i..<words.count].joined(separator: " "))
        }
        
        return terms
    }
}

struct PlaceCard: View {
    let place: WikipediaPlace
    @ObservedObject var distanceFormatter: DistanceFormatter
    
    var body: some View {
        VStack(spacing: 8) {
            if let imageURL = place.imageURL {
                CachedAsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        letterPlaceholder
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
                .frame(width: 140, height: 140)
                .clipped()
                .cornerRadius(10)
            } else {
                letterPlaceholder
            }
            
            Text(place.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 50)
            
            Text(distanceFormatter.format(place.distance))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .onTapGesture {
                    distanceFormatter.toggle()
                }
            
            if !place.shortDescription.isEmpty {
                Text(place.shortDescription)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 40)
            } else {
                Spacer().frame(height: 40)
            }
        }
        .frame(height: 260)
        .padding(.horizontal, 8)
        .foregroundColor(.primary)
    }
    
    var letterPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Text(place.firstLetter)
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 140, height: 140)
        .cornerRadius(10)
    }
}

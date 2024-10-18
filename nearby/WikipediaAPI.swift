import Foundation
import CoreLocation

class WikipediaAPI {
    static let shared = WikipediaAPI()
    private init() {}

    func fetchNearbyPlaces(location: CLLocationCoordinate2D, completion: @escaping (Result<[WikipediaPlace], Error>) -> Void) {
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=\(location.latitude)|\(location.longitude)&gsradius=10000&gslimit=24&format=json&maxlag=5"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("nearby/1.0 (https://github.com/ehamiter/nearby; ehamiter@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
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
                    
                    completion(.success(fetchedPlaces))
                } else {
                    completion(.failure(NSError(domain: "Unable to parse results", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchPlaceDetails(places: [WikipediaPlace], completion: @escaping (Result<[WikipediaPlace], Error>) -> Void) {
        let pageIds = places.map { String($0.id) }.joined(separator: "|")
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages|pageprops&exintro&explaintext&pageids=\(pageIds)&format=json&pithumbsize=200&maxlag=5"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("nearby/1.0 (https://github.com/ehamiter/nearby; ehamiter@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let query = json["query"] as? [String: Any],
                   let pages = query["pages"] as? [String: [String: Any]] {
                    
                    var updatedPlaces = places
                    
                    for (pageId, pageInfo) in pages {
                        if let index = updatedPlaces.firstIndex(where: { $0.id == Int(pageId) }) {
                            updatedPlaces[index].longDescription = pageInfo["extract"] as? String ?? ""
                            
                            if let pageprops = pageInfo["pageprops"] as? [String: Any],
                               let shortDesc = pageprops["wikibase-shortdesc"] as? String {
                                updatedPlaces[index].shortDescription = shortDesc
                            }
                            
                            if let thumbnail = pageInfo["thumbnail"] as? [String: Any],
                               let source = thumbnail["source"] as? String,
                               let imageUrl = URL(string: source) {
                                updatedPlaces[index].imageURL = imageUrl
                            }
                        }
                    }
                    
                    completion(.success(updatedPlaces))
                } else {
                    completion(.failure(NSError(domain: "Unable to parse results", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchWikimediaImage(for place: WikipediaPlace, completion: @escaping (Result<URL, Error>) -> Void) {
        let searchTerms = generateSearchTerms(from: place.title)
        
        func tryNextSearchTerm() {
            guard !searchTerms.isEmpty else {
                completion(.failure(NSError(domain: "No suitable image found", code: 0, userInfo: nil)))
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
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
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
                                    completion(.success(imageUrl))
                                    return
                                }
                            }
                        }
                        tryNextSearchTerm()
                    } else {
                        tryNextSearchTerm()
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
        
        tryNextSearchTerm()
    }
    
    private func generateSearchTerms(from input: String) -> [String] {
        let words = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var terms: [String] = []
        
        for i in 0..<words.count {
            terms.append(words[i..<words.count].joined(separator: " "))
        }
        
        return terms
    }
}

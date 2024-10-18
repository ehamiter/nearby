import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    private let url: URL
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty

    init(url: URL, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .onAppear { loadImage() }
    }

    private func loadImage() {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            print("Image loaded from cache: \(url)")
            self.phase = .success(Image(uiImage: image))
            return
        }
        
        print("Fetching image from network: \(url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.phase = .failure(error)
                }
                return
            }
            guard let data = data, let uiImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.phase = .failure(URLError(.badServerResponse))
                }
                return
            }
            DispatchQueue.main.async {
                self.phase = .success(Image(uiImage: uiImage))
            }
        }.resume()
    }
}

extension Image {
    func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

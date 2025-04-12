import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let perPage = 10
    private let dateFormatter = ISO8601DateFormatter()
    
    // MARK: - HTTP Methods
    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    // MARK: - Public Interface
    
    func clean() {
        photos.removeAll()
        lastLoadedPage = nil
        task?.cancel()
        task = nil
    }
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makeRequest(page: nextPage, perPage: perPage) else {
            print("[ImagesListService]: Ошибка - не удалось создать запрос")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.task = nil }
            
            if let error = error {
                print("[ImagesListService]: Ошибка сети - \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("[ImagesListService]: Ошибка - отсутствуют данные")
                return
            }
            
            do {
                let photoResults = try JSONDecoder().decode([PhotoResult].self, from: data)
                let newPhotos = photoResults.map { photoResult in
                    Photo(
                        id: photoResult.id,
                        size: CGSize(width: photoResult.width, height: photoResult.height),
                        createdAt: self.dateFormatter.date(from: photoResult.createdAt),
                        welcomeDescription: photoResult.description,
                        thumbImageURL: photoResult.urls.thumb,
                        largeImageURL: photoResult.urls.full,
                        isLiked: photoResult.likedByUser
                    )
                }
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                }
            } catch {
                print("[ImagesListService]: Ошибка декодирования - \(error), Данные: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        
        self.task = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let index = photos.firstIndex(where: { $0.id == photoId }) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Фото не найдено"])))
            return
        }
        
        let path = "/photos/\(photoId)/like"
        let httpMethod = isLike ? HTTPMethod.post : HTTPMethod.delete
        
        guard let url = URL(string: "https://api.unsplash.com" + path) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP ошибка: \(statusCode)"])))
                }
                return
            }
            
            DispatchQueue.main.async {
                self.photos[index].isLiked = isLike
                completion(.success(()))
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Helpers
    
    private func makeRequest(page: Int, perPage: Int) -> URLRequest? {
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService]: Ошибка - отсутствует токен")
            return nil
        }
        
        var components = URLComponents(string: "https://api.unsplash.com/photos")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let url = components?.url else {
            print("[ImagesListService]: Ошибка - неверный URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

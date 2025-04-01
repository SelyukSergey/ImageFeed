import Foundation
import UIKit

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
    
    var isValidLargeURL: Bool {
        return !largeImageURL.isEmpty && URL(string: largeImageURL) != nil
    }
    
    var isValidThumbURL: Bool {
        return !thumbImageURL.isEmpty && URL(string: thumbImageURL) != nil
    }
}

struct UrlsResult: Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt: String
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case description
        case likedByUser = "liked_by_user"
        case urls
    }
}
final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let perPage = 10
    private let dateFormatter = ISO8601DateFormatter()
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        let request = makeRequest(page: nextPage, perPage: perPage)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.task = nil }
            
            if let error = error {
                print("Error fetching photos: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
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
                    var uniquePhotos = self.photos
                    let existingIDs = Set(uniquePhotos.map { $0.id })
                    let filteredNewPhotos = newPhotos.filter { !existingIDs.contains($0.id) }
                    
                    if !filteredNewPhotos.isEmpty {
                        uniquePhotos.append(contentsOf: filteredNewPhotos)
                        self.photos = uniquePhotos
                        self.lastLoadedPage = nextPage
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self
                        )
                    }
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        self.task = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        let path = "/photos/\(photoId)/like"
        let httpMethod = isLike ? "POST" : "DELETE"
        
        var request = URLRequest(url: Constants.defaultBaseURL.appendingPathComponent(path))
        request.httpMethod = httpMethod
        request.setValue("Client-ID \(Constants.accessKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
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
                    completion(.failure(NetworkError.httpStatusCode(statusCode)))
                }
                return
            }
            
            do {
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlSessionError))
                    }
                    return
                }
                
                let photoResult = try JSONDecoder().decode(PhotoResult.self, from: data)
                DispatchQueue.main.async {
                    self.updatePhotoLikeStatus(photoId: photoId, isLiked: photoResult.likedByUser)
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    private func updatePhotoLikeStatus(photoId: String, isLiked: Bool) {
        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            let photo = photos[index]
            let newPhoto = Photo(
                id: photo.id,
                size: photo.size,
                createdAt: photo.createdAt,
                welcomeDescription: photo.welcomeDescription,
                thumbImageURL: photo.thumbImageURL,
                largeImageURL: photo.largeImageURL,
                isLiked: isLiked
            )
            photos = photos.withReplaced(itemAt: index, newValue: newPhoto)
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self
            )
        }
    }
    
    private func makeRequest(page: Int, perPage: Int) -> URLRequest {
        var components = URLComponents(url: Constants.defaultBaseURL, resolvingAgainstBaseURL: true)!
        components.path = "/photos"
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(Constants.accessKey)", forHTTPHeaderField: "Authorization")
        return request
    }
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> Array {
        var newArray = self
        newArray[index] = newValue
        return newArray
    }
}

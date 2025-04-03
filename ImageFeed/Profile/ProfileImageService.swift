import Foundation

struct UserResult: Codable {
    let profileImage: ProfileImage?
    
    struct ProfileImage: Codable {
        let small: String
        let medium: String
        let large: String
    }
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    // MARK: - Singleton
    static let shared = ProfileImageService()
    private var isFetching = false
    
    // MARK: - Properties
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private(set) var avatarURL: String?
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Initializer
    private init() {}
    
    // MARK: - Methods
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !isFetching else {
            print("Запрос уже выполняется")
            return
        }
        
        isFetching = true
        
        guard let token = tokenStorage.token else {
            print("Ошибка: отсутствует токен")
            completion(.failure(AuthServiceError.invalidRequest))
            isFetching = false
            return
        }
        
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.unsplash.com/users/\(encodedUsername)") else {
            print("Ошибка: неверный URL")
            completion(.failure(AuthServiceError.invalidRequest))
            isFetching = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer { self.isFetching = false }
            
            if let error = error {
                print("Ошибка сети: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("Ошибка: данные отсутствуют")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ сервера: \(jsonString)")
            }
            
            do {
                let userResult = try JSONDecoder().decode(UserResult.self, from: data)
                
                guard let profileImage = userResult.profileImage else {
                    print("Поле profile_image отсутствует или равно null")
                    completion(.failure(AuthServiceError.invalidRequest))
                    return
                }
                
                self.avatarURL = profileImage.large
                DispatchQueue.main.async {
                    completion(.success(profileImage.large))
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": profileImage.large]
                    )
                }
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Reset Method
    func reset() {
        avatarURL = nil
        task?.cancel()
        task = nil
        isFetching = false
    }
}

import Foundation

// MARK: - OAuthTokenResponseBody
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let expiresIn: Int?
    let refreshToken: String
    let scope: String
    let tokenType: String
    let createdAt: Int
    let userId: Int
    let username: String
}

// MARK: - AuthServiceError
enum AuthServiceError: Error {
    case invalidRequest
    case networkError(Error)
    case httpError(Int)
    case noData
    case decodingError(Error)
}

// MARK: - OAuth2Service
final class OAuth2Service {
    // MARK: - Singleton
    static let shared = OAuth2Service()
    
    private init() {}
    
    // MARK: - Private Properties
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private var authToken: String?
    
    // MARK: - Request Creation
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else {
            print("Ошибка: Невозможно создать baseURL")
            return nil
        }
        
        guard let url = URL(
            string: "/oauth/token"
            + "?client_id=\(Constants.accessKey)"
            + "&&client_secret=\(Constants.secretKey)"
            + "&&redirect_uri=\(Constants.redirectURI)"
            + "&&code=\(code)"
            + "&&grant_type=authorization_code",
            relativeTo: baseURL
        ) else {
            print("Ошибка: Невозможно создать URL для запроса")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    // MARK: - Fetch OAuth Token
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // проверка на дублирующие запросы
        if task != nil {
            if lastCode != code {
                task?.cancel()
            } else {
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        } else {
            if lastCode == code {
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // очистка текущей задачи
                self.task = nil
                self.lastCode = nil
                
                // обработка ошибок
                if let error = error {
                    print("Сетевая ошибка: \(error.localizedDescription)")
                    completion(.failure(AuthServiceError.networkError(error)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 300 {
                    print("Ошибка сервера: \(httpResponse.statusCode)")
                    completion(.failure(AuthServiceError.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    print("Ошибка: Нет данных в ответе")
                    completion(.failure(AuthServiceError.noData))
                    return
                }
                
                // декодирование ответа
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let oAuthTokenResponseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    self.authToken = oAuthTokenResponseBody.accessToken
                    
                    // сохранение токена в хранилище
                    OAuth2TokenStorage.shared.token = oAuthTokenResponseBody.accessToken
                    
                    completion(.success(oAuthTokenResponseBody.accessToken))
                } catch {
                    print("Ошибка декодирования: \(error.localizedDescription)")
                    completion(.failure(AuthServiceError.decodingError(error)))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
}

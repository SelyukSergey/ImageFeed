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

// MARK: - OAuth2Service
final class OAuth2Service {
    // MARK: - Singleton
    static let shared = OAuth2Service()
    
    private init() {}
    
    // MARK: - Properties
    private var authToken: String?
    
    // MARK: - Request Creation
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
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
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NSError(domain: "RequestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Невозможно создать запрос"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // логирование сетевых ошибок
            if let error = error {
                print("Сетевая ошибка: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // логирование ошибок HTTP-статусов
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 300 {
                let statusError = NSError(
                    domain: "HTTPError",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Ошибка сервера: \(httpResponse.statusCode)"]
                )
                print("Ошибка сервера: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(statusError))
                }
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "NoData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет данных в ответе"])
                print("Ошибка: Нет данных в ответе")
                DispatchQueue.main.async {
                    completion(.failure(noDataError))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let oAuthTokenResponseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                self.authToken = oAuthTokenResponseBody.accessToken
                
                // сохранение токена в хранилище
                OAuth2TokenStorage.shared.token = oAuthTokenResponseBody.accessToken
                
                DispatchQueue.main.async {
                    completion(.success(oAuthTokenResponseBody.accessToken))
                }
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}

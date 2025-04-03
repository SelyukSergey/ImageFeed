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
    
    private var isFetching = false
    
    // MARK: - Fetch OAuth Token
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if isFetching {
            print("[fetchOAuthToken]: Ошибка - запрос уже выполняется")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        if let currentTask = task {
            if lastCode == code {
                print("[fetchOAuthToken]: Ошибка - дублирующий запрос с кодом \(code)")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            currentTask.cancel()
        }
        
        lastCode = code
        isFetching = true
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[fetchOAuthToken]: Ошибка - неверный запрос")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                defer {
                    self.isFetching = false
                    self.task = nil
                    self.lastCode = nil
                }
                
                switch result {
                case .success(let oAuthTokenResponseBody):
                    self.authToken = oAuthTokenResponseBody.accessToken
                    OAuth2TokenStorage.shared.token = oAuthTokenResponseBody.accessToken
                    completion(.success(oAuthTokenResponseBody.accessToken))
                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Private Methods
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
}




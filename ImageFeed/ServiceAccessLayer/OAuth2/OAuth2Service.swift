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
    func makeOAuthTokenRequest(code: String) -> URLRequest {
        let baseURL = URL(string: "https://unsplash.com")!
        let url = URL(
            string: "/oauth/token"
            + "?client_id=\(AccessKey)"
            + "&&client_secret=\(SecretKey)"
            + "&&redirect_uri=\(RedirectURI)"
            + "&&code=\(code)"
            + "&&grant_type=authorization_code",
            relativeTo: baseURL
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    // MARK: - Fetch OAuth Token
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, any Error>) -> Void) {
        let request = makeOAuthTokenRequest(code: code)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let OAuthTokenResponseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                self.authToken = OAuthTokenResponseBody.accessToken
                
                // save token to storage
                OAuth2TokenStorage.shared.token = OAuthTokenResponseBody.accessToken
                
                DispatchQueue.main.async {
                    completion(.success(OAuthTokenResponseBody.accessToken))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}

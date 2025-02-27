import Foundation

final class OAuth2TokenStorage {
    // MARK: - Singleton
    static let shared = OAuth2TokenStorage()
    
    private init() {}
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "access_token"
    
    // MARK: - Token Management
    var token: String? {
        get {
            return userDefaults.string(forKey: tokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: tokenKey)
        }
    }
}

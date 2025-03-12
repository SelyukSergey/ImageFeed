import Foundation

// MARK: - ProfileResult
struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
}

// MARK: - Profile
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

// MARK: - ProfileService
final class ProfileService {
    // MARK: - Singleton
    static let shared = ProfileService()
    
    private init() {}
    
    // MARK: - Properties
    private(set) var profile: Profile?
    private var isFetching = false
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        guard !isFetching else {
            print("[fetchProfile]: Ошибка - запрос уже выполняется")
            return
        }
        isFetching = true
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("[fetchProfile]: Ошибка - неверный URL")
            completion(.failure(AuthServiceError.invalidRequest))
            isFetching = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                self?.isFetching = false
                
                switch result {
                case .success(let profileResult):
                    let profile = Profile(
                        username: profileResult.username,
                        name: "\(profileResult.firstName ?? "") \(profileResult.lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines),
                        loginName: "@\(profileResult.username)",
                        bio: profileResult.bio
                    )
                    self?.profile = profile
                    completion(.success(profile))
                case .failure(let error):
                    print("[fetchProfile]: Ошибка - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

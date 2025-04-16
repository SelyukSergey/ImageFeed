import Foundation

protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void)
    func reset()
}

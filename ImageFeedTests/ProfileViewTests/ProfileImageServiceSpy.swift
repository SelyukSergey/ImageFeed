@testable import ImageFeed
import Foundation

final class ProfileImageServiceSpy: ProfileImageServiceProtocol {
    var avatarURL: String?
    var fetchProfileImageURLCalled = false
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        fetchProfileImageURLCalled = true
    }
    
    func reset() {
        avatarURL = nil
    }
}

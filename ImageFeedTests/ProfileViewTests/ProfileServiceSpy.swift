@testable import ImageFeed
import Foundation

final class ProfileServiceSpy: ProfileServiceProtocol {
    var profile: Profile?
    var fetchProfileCalled = false
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        fetchProfileCalled = true
    }
    
    func reset() {
        profile = nil
    }
}

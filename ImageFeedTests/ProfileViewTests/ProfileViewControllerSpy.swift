@testable import ImageFeed
import Foundation

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    
    // States
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var showDefaultAvatarCalled = false
    var showLogoutAlertCalled = false
    
    // Values
    var name: String?
    var loginName: String?
    var bio: String?
    var avatarURL: URL?
    
    // Completion handlers
    var updateProfileDetailsCompletion: (() -> Void)?
    var updateAvatarCompletion: (() -> Void)?
    var showDefaultAvatarCompletion: (() -> Void)?
    
    func updateProfileDetails(name: String, loginName: String, bio: String) {
        updateProfileDetailsCalled = true
        self.name = name
        self.loginName = loginName
        self.bio = bio
        updateProfileDetailsCompletion?()
    }
    
    func updateAvatar(with url: URL) {
        updateAvatarCalled = true
        self.avatarURL = url
        updateAvatarCompletion?()
    }
    
    func showDefaultAvatar() {
        showDefaultAvatarCalled = true
        showDefaultAvatarCompletion?()
    }
    
    func showLogoutAlert() {
        showLogoutAlertCalled = true
    }
}

import UIKit
import Kingfisher

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol
    private let profileLogoutService: ProfileLogoutServiceProtocol
    private var profileImageServiceObserver: NSObjectProtocol?
    
    init(
        profileService: ProfileServiceProtocol = ProfileService.shared,
        profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared,
        profileLogoutService: ProfileLogoutServiceProtocol = ProfileLogoutService.shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.profileLogoutService = profileLogoutService
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func viewDidLoad() {
        updateProfileDetails()
        updateAvatar()
        setupObserver()
    }
    
    func didTapLogoutButton() {
        profileLogoutService.logout()
    }
    
    func updateAvatar() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let profileImageURL = self.profileImageService.avatarURL,
               let url = URL(string: profileImageURL) {
                self.view?.updateAvatar(with: url)
            } else {
                self.view?.showDefaultAvatar()
            }
        }
    }
    
    func updateProfileDetails() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let profile = self.profileService.profile else {
                return
            }
            
            let bioText = profile.bio ?? ""
            self.view?.updateProfileDetails(
                name: profile.name,
                loginName: profile.loginName,
                bio: bioText
            )
        }
    }
    
    private func setupObserver() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.updateAvatar()
        }
    }
}

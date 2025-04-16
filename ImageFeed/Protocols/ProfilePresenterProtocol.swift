import Foundation

protocol ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    
    func viewDidLoad()
    func didTapLogoutButton()
    func updateAvatar()
    func updateProfileDetails()
}

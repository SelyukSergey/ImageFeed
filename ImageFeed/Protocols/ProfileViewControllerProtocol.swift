import UIKit

protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(name: String, loginName: String, bio: String)
    func updateAvatar(with url: URL)
    func showDefaultAvatar()
    func showLogoutAlert()
}

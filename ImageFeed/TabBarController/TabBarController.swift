import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        self.viewControllers = [imagesListViewController, profileViewController]
        
        setupTabBarAppearance()
    }
    
    private func setupTabBarAppearance() {
        tabBar.barTintColor = UIColor(named: "YP Black")
        tabBar.isTranslucent = false
        
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor(named: "YP Gray")
        
        view.backgroundColor = UIColor(named: "YP Black")
    }
}

import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imagesListViewController = ImagesListViewController()
        let imagesListNavigationController = UINavigationController(rootViewController: imagesListViewController)
        imagesListNavigationController.tabBarItem = UITabBarItem(
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
        
        self.viewControllers = [imagesListNavigationController, profileViewController]
        
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

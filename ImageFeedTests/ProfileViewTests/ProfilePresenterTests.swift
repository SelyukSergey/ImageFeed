@testable import ImageFeed
import XCTest

final class ProfilePresenterTests: XCTestCase {
    var presenter: ProfilePresenter!
    var viewController: ProfileViewControllerSpy!
    var profileService: ProfileServiceSpy!
    var profileImageService: ProfileImageServiceSpy!
    var profileLogoutService: ProfileLogoutServiceSpy!
    
    override func setUp() {
        super.setUp()
        
        viewController = ProfileViewControllerSpy()
        profileService = ProfileServiceSpy()
        profileImageService = ProfileImageServiceSpy()
        profileLogoutService = ProfileLogoutServiceSpy()
        
        presenter = ProfilePresenter(
            profileService: profileService,
            profileImageService: profileImageService,
            profileLogoutService: profileLogoutService
        )
        
        presenter.view = viewController
    }
    
    override func tearDown() {
        presenter = nil
        viewController = nil
        profileService = nil
        profileImageService = nil
        profileLogoutService = nil
        
        super.tearDown()
    }
    
    func testViewDidLoadUpdatesProfileDetails() {
        // Given
        let profile = Profile(
            username: "testuser",
            name: "Test User",
            loginName: "@testuser",
            bio: "Test bio"
        )
        profileService.profile = profile
        
        let expectation = XCTestExpectation(description: "Profile details updated")
        viewController.updateProfileDetailsCompletion = {
            expectation.fulfill()
        }
        
        // When
        presenter.viewDidLoad()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewController.updateProfileDetailsCalled)
        XCTAssertEqual(viewController.name, profile.name)
        XCTAssertEqual(viewController.loginName, profile.loginName)
        XCTAssertEqual(viewController.bio, profile.bio)
    }
    
    func testViewDidLoadUpdatesAvatarWhenURLExists() {
        // Given
        let testURL = "https://example.com/avatar.jpg"
        profileImageService.avatarURL = testURL
        
        let expectation = XCTestExpectation(description: "Avatar updated")
        viewController.updateAvatarCompletion = {
            expectation.fulfill()
        }
        
        // When
        presenter.viewDidLoad()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewController.updateAvatarCalled)
        XCTAssertEqual(viewController.avatarURL?.absoluteString, testURL)
    }
    
    func testViewDidLoadShowsDefaultAvatarWhenURLMissing() {
        // Given
        profileImageService.avatarURL = nil
        
        let expectation = XCTestExpectation(description: "Default avatar shown")
        viewController.showDefaultAvatarCompletion = {
            expectation.fulfill()
        }
        
        // When
        presenter.viewDidLoad()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewController.showDefaultAvatarCalled)
        XCTAssertFalse(viewController.updateAvatarCalled)
    }
    
    func testDidTapLogoutButtonCallsLogoutService() {
        // When
        presenter.didTapLogoutButton()
        
        // Then
        XCTAssertTrue(profileLogoutService.logoutCalled)
    }
    
    func testNotificationObserverUpdatesAvatar() {
        // Given
        let testURL = "https://example.com/new-avatar.jpg"
        profileImageService.avatarURL = testURL
        
        let expectation = XCTestExpectation(description: "Notification received and avatar updated")
        viewController.updateAvatarCompletion = {
            expectation.fulfill()
        }
        
        // When
        presenter.viewDidLoad() 
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: nil,
            userInfo: ["URL": testURL]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewController.updateAvatarCalled)
        XCTAssertEqual(viewController.avatarURL?.absoluteString, testURL)
    }
}

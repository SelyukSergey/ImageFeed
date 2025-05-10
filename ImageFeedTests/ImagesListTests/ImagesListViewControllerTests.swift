@testable import ImageFeed
import XCTest

final class ImagesListViewControllerTests: XCTestCase {
    
    var viewController: ImagesListViewControllerSpy!
    var presenter: ImagesListPresenterSpy!
    
    override func setUp() {
        super.setUp()
        viewController = ImagesListViewControllerSpy()
        presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
    }
    
    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }
    
    func testViewDidLoadCallsPresenter() {
        // Given
        let sut = ImagesListViewController()
        sut.presenter = presenter
        
        // When
        _ = sut.view
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testUpdateTableViewAnimated() {
        // When
        viewController.updateTableViewAnimated()
        
        // Then
        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
    }
    
    func testShowLikeErrorAlert() {
        // Given
        let testError = NSError(domain: "test", code: 123)
        
        // When
        viewController.showLikeErrorAlert(testError)
        
        // Then
        XCTAssertTrue(viewController.showLikeErrorAlertCalled)
        XCTAssertNotNil(viewController.likeError)
        XCTAssertEqual((viewController.likeError! as NSError).code, testError.code)
        XCTAssertEqual((viewController.likeError! as NSError).domain, testError.domain)
    }
    
    func testShowURLErrorAlert() {
        // When
        viewController.showURLErrorAlert()
        
        // Then
        XCTAssertTrue(viewController.showURLErrorAlertCalled)
    }
    
    func testPerformBatchUpdates() {
        // Given
        let oldCount = 5
        let newCount = 10
        
        // When
        viewController.performBatchUpdates(oldCount: oldCount, newCount: newCount)
        
        // Then
        XCTAssertTrue(viewController.performBatchUpdatesCalled)
        XCTAssertEqual(viewController.oldCount, oldCount)
        XCTAssertEqual(viewController.newCount, newCount)
    }
}

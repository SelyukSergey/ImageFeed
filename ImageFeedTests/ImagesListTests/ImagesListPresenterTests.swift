@testable import ImageFeed
import XCTest

final class ImagesListPresenterTests: XCTestCase {
    var presenter: ImagesListPresenterSpy!
    var viewController: ImagesListViewControllerSpy!
    
    override func setUp() {
        super.setUp()
        presenter = ImagesListPresenterSpy()
        viewController = ImagesListViewControllerSpy()
        presenter.view = viewController
    }
    
    override func tearDown() {
        presenter = nil
        viewController = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testFetchPhotosNextPageIfNeeded() {
        // When
        presenter.fetchPhotosNextPageIfNeeded()
        
        // Then
        XCTAssertTrue(presenter.fetchPhotosNextPageIfNeededCalled)
    }
    
    func testChangeLikeSuccess() {
        // Given
        let photoId = "testPhotoId"
        let isLike = true
        let expectation = self.expectation(description: "ChangeLike completion")
        presenter.shouldSucceed = true
        
        // When
        presenter.changeLike(for: photoId, isLike: isLike) { result in
            // Then
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Completion не должен возвращать ошибку в этом сценарии")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertTrue(presenter.changeLikeCalled)
    }
    
    func testChangeLikeFailure() {
        // Given
        let photoId = "testPhotoId"
        let isLike = true
        let expectation = self.expectation(description: "ChangeLike completion")
        presenter.shouldSucceed = false
        
        // When
        presenter.changeLike(for: photoId, isLike: isLike) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Completion должен возвращать ошибку в этом сценарии")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertTrue(presenter.changeLikeCalled)
    }
    
    func testPhotoAtIndex() {
        // Given
        let testIndex = 0
        let testPhoto = TestPhotoFactory.createPhoto()
        presenter.stubbedPhoto = testPhoto
        
        // When
        let result = presenter.photo(at: testIndex)
        
        // Then
        XCTAssertTrue(presenter.photoAtIndexCalled)
        XCTAssertEqual(result?.id, testPhoto.id)
    }
    
    func testCalculateCellHeight() {
        // Given
        let testPhoto = TestPhotoFactory.createPhoto()
        let testWidth: CGFloat = 320
        let expectedHeight: CGFloat = 480
        presenter.stubbedCellHeight = expectedHeight
        
        // When
        let result = presenter.calculateCellHeight(for: testPhoto, tableViewWidth: testWidth)
        
        // Then
        XCTAssertTrue(presenter.calculateCellHeightCalled)
        XCTAssertEqual(result, expectedHeight)
    }
}

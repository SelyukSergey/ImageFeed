@testable import ImageFeed
import UIKit

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var updateTableViewAnimatedCalled = false
    var performBatchUpdatesCalled = false
    var showLikeErrorAlertCalled = false
    var showURLErrorAlertCalled = false
    
    var likeError: Error?
    var oldCount: Int?
    var newCount: Int?
    
    var presenter: ImagesListPresenterProtocol!
    
    func updateTableViewAnimated() {
        updateTableViewAnimatedCalled = true
    }
    
    func performBatchUpdates(oldCount: Int, newCount: Int) {
        performBatchUpdatesCalled = true
        self.oldCount = oldCount
        self.newCount = newCount
    }
    
    func showLikeErrorAlert(_ error: Error) {
        showLikeErrorAlertCalled = true
        likeError = error
    }
    
    func showURLErrorAlert() {
        showURLErrorAlertCalled = true
    }
}

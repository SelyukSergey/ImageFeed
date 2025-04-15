import UIKit

protocol ImagesListViewControllerProtocol: AnyObject {
    func updateTableViewAnimated()
    func showLikeErrorAlert(_ error: Error)
    func showURLErrorAlert()
    func performBatchUpdates(oldCount: Int, newCount: Int)
}

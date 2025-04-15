import UIKit

protocol ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol? { get set }
    var photosCount: Int { get }
    var dateFormatter: DateFormatter { get }
    
    func viewDidLoad()
    func photo(at index: Int) -> Photo?
    func fetchPhotosNextPageIfNeeded()
    func changeLike(for photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    func calculateCellHeight(for photo: Photo, tableViewWidth: CGFloat) -> CGFloat
}

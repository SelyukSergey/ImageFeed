import UIKit
import Kingfisher

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    
    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var photosCount: Int {
        photos.count
    }
    
    init() {
        setupNotificationObserver()
    }
    
    deinit {
        imagesListServiceObserver.map {
            NotificationCenter.default.removeObserver($0)
        }
    }
    
    func viewDidLoad() {
        loadInitialPhotos()
    }
    
    func photo(at index: Int) -> Photo? {
        guard index >= 0 && index < photos.count else { return nil }
        return photos[index]
    }
    
    func fetchPhotosNextPageIfNeeded() {
        imagesListService.fetchPhotosNextPage()
    }
    
    func changeLike(for photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        imagesListService.changeLike(photoId: photoId, isLike: isLike) { [weak self] result in
            switch result {
            case .success:
                if let newPhoto = self?.imagesListService.photos.first(where: { $0.id == photoId }),
                   let index = self?.photos.firstIndex(where: { $0.id == photoId }) {
                    self?.photos[index] = newPhoto
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func calculateCellHeight(for photo: Photo, tableViewWidth: CGFloat) -> CGFloat {
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableViewWidth - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    private func setupNotificationObserver() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.updateTableViewAnimated()
            }
    }
    
    private func loadInitialPhotos() {
        UIBlockingProgressHUD.animate()
        
        if imagesListService.photos.isEmpty {
            imagesListService.fetchPhotosNextPage()
        } else {
            photos = imagesListService.photos
            view?.updateTableViewAnimated()
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        
        if oldCount != newCount {
            view?.performBatchUpdates(oldCount: oldCount, newCount: newCount)
        }
        
        UIBlockingProgressHUD.dismiss()
    }
}

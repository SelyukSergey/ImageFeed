import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .ypBlack
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return tableView
    }()
    
    private var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNotificationObserver()
        loadInitialPhotos()
    }
    
    deinit {
        imagesListServiceObserver.map {
            NotificationCenter.default.removeObserver($0)
        }
    }
    
    private func setupViews() {
        view.backgroundColor = .ypBlack
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
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
            tableView.reloadData()
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
        
        UIBlockingProgressHUD.dismiss()
    }
    
    private func showURLErrorAlert() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Некорректная ссылка на изображение",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showLikeErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось поставить лайк: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        
        let photo = photos[indexPath.row]
        cell.configure(with: photo, using: dateFormatter)
        cell.delegate = self
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let photo = photos[indexPath.row]
        guard photo.isValidLargeURL else {
            showURLErrorAlert()
            return
        }
        
        let singleImageVC = SingleImageViewController()
        singleImageVC.imageUrl = photo.largeImageURL
        singleImageVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(singleImageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let newIndexPath = self?.tableView.indexPath(for: cell),
                       let newPhoto = self?.imagesListService.photos.first(where: { $0.id == photo.id }) {
                        self?.photos[newIndexPath.row] = newPhoto
                        cell.setIsLiked(newPhoto.isLiked)
                    }
                case .failure(let error):
                    self?.showLikeErrorAlert(error)
                    cell.setIsLiked(photo.isLiked)
                }
            }
        }
    }
}

import UIKit

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .ypBlack
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return tableView
    }()
    
    private var presenter: ImagesListPresenterProtocol = ImagesListPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.view = self
        setupViews()
        presenter.viewDidLoad()
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
    
    // MARK: - ImagesListViewControllerProtocol
    
    func updateTableViewAnimated() {
        tableView.reloadData()
    }
    
    func showLikeErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось поставить лайк: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showURLErrorAlert() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Некорректная ссылка на изображение",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func performBatchUpdates(oldCount: Int, newCount: Int) {
        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.photosCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        
        if let photo = presenter.photo(at: indexPath.row) {
            cell.configure(with: photo, using: presenter.dateFormatter)
            cell.delegate = self
        }
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let photo = presenter.photo(at: indexPath.row) else { return }
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
        guard let photo = presenter.photo(at: indexPath.row) else { return 0 }
        return presenter.calculateCellHeight(for: photo, tableViewWidth: tableView.bounds.width)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == presenter.photosCount - 1 {
            presenter.fetchPhotosNextPageIfNeeded()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let photo = presenter.photo(at: indexPath.row) else { return }
        
        presenter.changeLike(for: photo.id, isLike: !photo.isLiked) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let newPhoto = self?.presenter.photo(at: indexPath.row) {
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

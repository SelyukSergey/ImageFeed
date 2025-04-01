import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    weak var delegate: ImagesListCellDelegate?
    
    let cellImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let likeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(named: "YP White")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "scribble")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let loaderContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .ypLightGray
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private var currentImageURL: URL?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        currentImageURL = nil
        hideLoader()
        hidePlaceholder()
    }
    
    func configure(with photo: Photo, using dateFormatter: DateFormatter) {
        dateLabel.text = photo.createdAt.map { dateFormatter.string(from: $0) } ?? ""
        setIsLiked(photo.isLiked)
        loadImage(from: photo.thumbImageURL)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showPlaceholder()
            return
        }
        
        currentImageURL = url
        showPlaceholder()
        
        cellImage.kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage,
                .backgroundDecode
            ],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let imageResult):
                    if self.currentImageURL == imageResult.source.url {
                        self.cellImage.image = imageResult.image
                        self.hidePlaceholder()
                    }
                case .failure(let error):
                    print("Image loading error: \(error.localizedDescription)")
                    self.showPlaceholder()
                }
            }
        )
    }
    
    private func showPlaceholder() {
        placeholderImageView.isHidden = false
        cellImage.backgroundColor = .ypBackground
    }
    
    private func hidePlaceholder() {
        placeholderImageView.isHidden = true
        cellImage.backgroundColor = .clear
    }
    
    private func showLoader() {
        loaderContainer.isHidden = false
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .ypBlack
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loaderContainer.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loaderContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loaderContainer.centerYAnchor)
        ])
    }
    
    private func hideLoader() {
        loaderContainer.isHidden = true
        loaderContainer.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func setupViews() {
        backgroundColor = .ypBlack
        
        contentView.addSubview(cellImage)
        contentView.addSubview(placeholderImageView)
        contentView.addSubview(likeButton)
        contentView.addSubview(dateLabel)
        contentView.addSubview(loaderContainer)
        
        likeButton.addTarget(self, action: #selector(likeButtonClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            placeholderImageView.centerXAnchor.constraint(equalTo: cellImage.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: cellImage.centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 83),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 75),
            
            loaderContainer.centerXAnchor.constraint(equalTo: cellImage.centerXAnchor),
            loaderContainer.centerYAnchor.constraint(equalTo: cellImage.centerYAnchor),
            loaderContainer.widthAnchor.constraint(equalToConstant: 51),
            loaderContainer.heightAnchor.constraint(equalToConstant: 51),
            
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor, constant: 8),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor, constant: -8),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: cellImage.trailingAnchor, constant: -8)
        ])
        
        selectionStyle = .none
    }
    
    @objc private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
}

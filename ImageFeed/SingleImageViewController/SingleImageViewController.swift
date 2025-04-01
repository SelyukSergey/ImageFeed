import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var shareButton: UIButton!
    
    private let loaderContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .ypLightGray
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateImage(image)
            updateShareButton()
        }
    }
    
    var imageUrl: String? {
        didSet {
            guard isViewLoaded else { return }
            loadImageFromUrl()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadInitialContent()
        setupNavigationBar()
    }
    
    private func setupViews() {
        view.backgroundColor = .ypBlack
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        view.addSubview(scrollView)
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        
        shareButton = UIButton(type: .system)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(named: "share_button")?.withRenderingMode(.alwaysOriginal), for: .normal)
        shareButton.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        shareButton.isHidden = true
        view.addSubview(shareButton)
        
        view.addSubview(loaderContainer)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            loaderContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loaderContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loaderContainer.widthAnchor.constraint(equalToConstant: 51),
            loaderContainer.heightAnchor.constraint(equalToConstant: 51),
            
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadInitialContent() {
        if let image = image {
            updateImage(image)
        } else if imageUrl != nil {
            loadImageFromUrl()
        }
    }
    
    private func setupNavigationBar() {
        let backButton = UIBarButtonItem(
            image: UIImage(named: "nav_back_button_white")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    private func loadImageFromUrl() {
        guard let imageUrlString = imageUrl, let url = URL(string: imageUrlString) else {
            return
        }
        
        showLoader()
        
        imageView.kf.setImage(
            with: url,
            options: [.transition(.fade(0.2))],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                self.hideLoader()
                
                switch result {
                case .success(let imageResult):
                    self.image = imageResult.image
                    self.rescaleAndCenterImageInScrollView(image: imageResult.image)
                case .failure(let error):
                    print("Image loading error: \(error.localizedDescription)")
                }
                self.updateShareButton()
            }
        )
    }
    
    private func showLoader() {
        loaderContainer.isHidden = false
        let activityIndicator = UIActivityIndicatorView(style: .medium)
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
    
    private func updateImage(_ image: UIImage?) {
        imageView.image = image
        if let image = image {
            rescaleAndCenterImageInScrollView(image: image)
        }
        updateShareButton()
    }
    
    private func updateShareButton() {
        shareButton.isHidden = image == nil
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        guard imageSize.width > 0, imageSize.height > 0 else {
            print("Invalid image dimensions")
            return
        }
        
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(hScale, vScale)
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        updateInsets(for: scrollView)
    }
    
    private func updateInsets(for scrollView: UIScrollView) {
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        
        let verticalInset = max((boundsSize.height - contentSize.height) / 2, 0)
        let horizontalInset = max((boundsSize.width - contentSize.width) / 2, 0)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    @objc private func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapShareButton() {
        guard let image = image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        updateInsets(for: scrollView)
    }
}

extension SingleImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}

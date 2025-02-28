import UIKit
import ProgressHUD

protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

final class AuthViewController: UIViewController {
    private let ShowWebViewSegueIdentifier = "ShowWebView"
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let oauth2Service = OAuth2Service.shared
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == ShowWebViewSegueIdentifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        
        guard let webViewViewController = segue.destination as? WebViewViewController else {
            fatalError("Failed to prepare for \(ShowWebViewSegueIdentifier)")
        }
        
        webViewViewController.delegate = self
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true)
        
        UIBlockingProgressHUD.animate()

        oauth2Service.fetchOAuthToken(code) { [weak self] (result: Result<String, Error>) in
            guard let self = self else { return }

            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success(let token):
                self.delegate?.authViewController(self, didAuthenticateWithCode: token)
            
            case .failure(let error):
                print("Ошибка авторизации: \(error.localizedDescription)")
                self.showErrorAlert(message: "Не удалось авторизоваться. Пожалуйста, попробуйте снова.")
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("Авторизация отменена пользователем")
        dismiss(animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

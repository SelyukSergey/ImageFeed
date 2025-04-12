import Foundation
import UIKit

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
    
    var isValidLargeURL: Bool {
        !largeImageURL.isEmpty && URL(string: largeImageURL) != nil
    }
    
    var isValidThumbURL: Bool {
        !thumbImageURL.isEmpty && URL(string: thumbImageURL) != nil
    }
}

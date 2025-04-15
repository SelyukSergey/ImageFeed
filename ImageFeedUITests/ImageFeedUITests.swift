import XCTest

final class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    let email = ""
    let password = ""
    let fullName = ""
    let userName = ""
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["UITEST"]
        app.launch()
    }
    
    func testAuth() throws {
        app.buttons[AccessibilityIds.loginButton].tap()
        
        let webView = app.webViews[AccessibilityIds.webWiew]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))
        
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 15))
        
        loginTextField.tap()
        loginTextField.typeText(email)
        loginTextField.swipeUp()
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 15))
        passwordTextField.tap()
        
        sleep(2)
        passwordTextField.typeText(password)
        
        sleep(2)
        webView.buttons["Login"].tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
    }
    
    func testFeed() throws {
        let tableQuery = app.tables
        let cell = tableQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.swipeUp()
        
        sleep(2)
        
        let cellToLike = tableQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 15))
        
        let likeButton = cellToLike.buttons[AccessibilityIds.likeButton]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 15))
        
        likeButton.tap()
        
        sleep(2)
        likeButton.tap()
        
        sleep(3)
        cellToLike.tap()
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 15))
        
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        
        let backButton = app.buttons[AccessibilityIds.backButton]
        backButton.tap()
    }
    
    func testProfile() throws {
        sleep(3)
        
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        XCTAssertTrue(app.staticTexts[fullName].exists)
        XCTAssertTrue(app.staticTexts[userName].exists)
        
        app.buttons[AccessibilityIds.logoutButton].tap()
        
        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
        
        XCTAssertTrue(app.otherElements[AccessibilityIds.authViewController].waitForExistence(timeout: 15))
    }
}

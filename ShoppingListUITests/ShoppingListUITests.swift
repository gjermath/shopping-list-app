import XCTest

final class ShoppingListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Auth

    func testDebugSignIn() throws {
        let signInButton = app.buttons["Sign in with test account"]
        if signInButton.waitForExistence(timeout: 5) {
            signInButton.tap()

            // Should land on My Lists tab
            let myLists = app.navigationBars["My Lists"]
            XCTAssertTrue(myLists.waitForExistence(timeout: 10), "Should navigate to My Lists after sign-in")
        } else {
            // Already signed in
            XCTAssertTrue(app.navigationBars["My Lists"].exists)
        }
    }

    // MARK: - List Creation

    func testCreateList() throws {
        signInIfNeeded()

        // Tap +
        let addButton = app.navigationBars.buttons["plus"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Fill in list name
        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test List")

        // Tap Create
        app.buttons["Create"].tap()

        // List should appear
        let listCell = app.staticTexts["UI Test List"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 10), "Created list should appear in My Lists")
    }

    // MARK: - Item Addition

    func testAddItemToList() throws {
        signInIfNeeded()
        createListIfNeeded(name: "Test Items List")

        // Open the list
        let listCell = app.staticTexts["Test Items List"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 10))
        listCell.tap()

        // Wait for list detail to load
        let inputField = app.textFields["Add items..."]
        XCTAssertTrue(inputField.waitForExistence(timeout: 5), "Input field should appear")

        // Type in the input bar
        inputField.tap()
        inputField.typeText("Milk")

        // Submit via Done button on keyboard
        app.keyboards.buttons["Done"].tap()

        // Wait for keyboard to dismiss and item to appear via Firestore
        sleep(3)

        // Wait for Firestore listener to fire and item to render
        let milkPredicate = NSPredicate(format: "label CONTAINS[c] 'Milk'")
        let item = app.descendants(matching: .any).matching(milkPredicate).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 20), "Added item should appear in list")
    }

    // MARK: - Tab Navigation

    func testTabNavigation() throws {
        signInIfNeeded()

        // Lists tab is default
        XCTAssertTrue(app.navigationBars["My Lists"].waitForExistence(timeout: 5))

        // Switch to Activity tab
        app.tabBars.buttons["Activity"].tap()
        let activityNav = app.navigationBars["Activity"]
        XCTAssertTrue(activityNav.waitForExistence(timeout: 5))

        // Switch to Profile tab
        app.tabBars.buttons["Profile"].tap()
        let profileNav = app.navigationBars["Profile"]
        XCTAssertTrue(profileNav.waitForExistence(timeout: 5))

        // Back to Lists
        app.tabBars.buttons["Lists"].tap()
        XCTAssertTrue(app.navigationBars["My Lists"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func signInIfNeeded() {
        let signInButton = app.buttons["Sign in with test account"]
        if signInButton.waitForExistence(timeout: 3) {
            signInButton.tap()
            let myLists = app.navigationBars["My Lists"]
            XCTAssertTrue(myLists.waitForExistence(timeout: 10))
        }
    }

    private func createListIfNeeded(name: String) {
        let listCell = app.staticTexts[name]
        if listCell.waitForExistence(timeout: 3) {
            return // List already exists
        }

        let addButton = app.navigationBars.buttons["plus"]
        guard addButton.waitForExistence(timeout: 5) else { return }
        addButton.tap()

        let nameField = app.textFields["List name"]
        guard nameField.waitForExistence(timeout: 5) else { return }
        nameField.tap()
        nameField.typeText(name)
        app.buttons["Create"].tap()

        // Wait for sheet to dismiss and list to appear
        XCTAssertTrue(listCell.waitForExistence(timeout: 10))
    }
}

import XCTest
@testable import ShoppingList

final class ItemTests: XCTestCase {
    func testNewItemDefaultsToActive() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.status, .active)
        XCTAssertFalse(item.isCompleted)
    }

    func testNewItemDefaultsToUnflagged() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertFalse(item.flagged)
    }

    func testResolvedCategoryParsesValidCategory() {
        let item = Item(name: "Milk", category: "Dairy", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .dairy)
    }

    func testResolvedCategoryFallsBackToOther() {
        let item = Item(name: "Stuff", category: "Unknown", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .other)
    }

    func testResolvedCategoryNilIsOther() {
        let item = Item(name: "Stuff", category: nil, addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .other)
    }

    func testCompletedItemReportsIsCompleted() {
        var item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        item.status = .completed
        XCTAssertTrue(item.isCompleted)
    }

    func testDefaultSourceIsText() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.source, .text)
    }
}

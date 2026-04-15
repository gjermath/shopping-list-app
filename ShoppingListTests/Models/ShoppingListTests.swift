import XCTest
@testable import ShoppingList

final class ShoppingListModelTests: XCTestCase {
    func testIsMemberReturnsTrueForMember() {
        var list = ShoppingList(
            name: "Groceries",
            ownerId: "owner1",
            memberIds: ["owner1", "user2"],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: "abc123"
        )
        list.currentUserId = "user2"
        XCTAssertTrue(list.isMember)
    }

    func testIsMemberReturnsFalseForNonMember() {
        var list = ShoppingList(
            name: "Groceries",
            ownerId: "owner1",
            memberIds: ["owner1"],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: "abc123"
        )
        list.currentUserId = "stranger"
        XCTAssertFalse(list.isMember)
    }
}

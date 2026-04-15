import XCTest
@testable import ShoppingList

final class ItemCategoryTests: XCTestCase {
    func testAllCasesHaveEmoji() {
        for category in ItemCategory.allCases {
            XCTAssertFalse(category.emoji.isEmpty, "\(category.rawValue) missing emoji")
        }
    }

    func testAllCasesHaveUniqueSortOrder() {
        let orders = ItemCategory.allCases.map(\.sortOrder)
        XCTAssertEqual(orders.count, Set(orders).count, "Sort orders must be unique")
    }

    func testRawValuesMatchDisplayStrings() {
        XCTAssertEqual(ItemCategory.produce.rawValue, "Produce")
        XCTAssertEqual(ItemCategory.personalCare.rawValue, "Personal Care")
        XCTAssertEqual(ItemCategory.other.rawValue, "Other")
    }

    func testCodableRoundTrip() throws {
        let original = ItemCategory.dairy
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ItemCategory.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

import Foundation
import FirebaseFunctions

struct ParsedItem: Codable, Identifiable {
    let name: String
    let quantity: String?
    let category: String?

    var id: String { name + (quantity ?? "") }
}

struct DuplicateGroup: Codable, Identifiable {
    let items: [String]
    let suggestion: String

    var id: String { items.joined() }
}

class AIService {
    private let functions = Functions.functions()

    func parseImage(imageUrl: String) async throws -> [ParsedItem] {
        let result = try await functions.httpsCallable("parseImage").call(["imageUrl": imageUrl])

        guard let data = result.data as? [String: Any],
              let itemDicts = data["items"] as? [[String: Any]] else {
            return []
        }

        return itemDicts.compactMap { dict in
            guard let name = dict["name"] as? String else { return nil }
            return ParsedItem(
                name: name,
                quantity: dict["quantity"] as? String,
                category: dict["category"] as? String
            )
        }
    }

    func suggestFrequentItems(listId: String) async throws -> [String] {
        let result = try await functions.httpsCallable("suggestFrequentItems").call(["listId": listId])

        guard let data = result.data as? [String: Any],
              let suggestions = data["suggestions"] as? [String] else {
            return []
        }

        return suggestions
    }

    func reviewDuplicates(listId: String) async throws -> [DuplicateGroup] {
        let result = try await functions.httpsCallable("reviewDuplicates").call(["listId": listId])

        guard let data = result.data as? [String: Any],
              let groupDicts = data["groups"] as? [[String: Any]] else {
            return []
        }

        return groupDicts.compactMap { dict in
            guard let items = dict["items"] as? [String],
                  let suggestion = dict["suggestion"] as? String else { return nil }
            return DuplicateGroup(items: items, suggestion: suggestion)
        }
    }
}

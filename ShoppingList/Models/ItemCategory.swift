import Foundation

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case bakery = "Bakery"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case pantry = "Pantry"
    case household = "Household"
    case personalCare = "Personal Care"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .produce:      return "🥬"
        case .dairy:        return "🥛"
        case .meat:         return "🥩"
        case .bakery:       return "🍞"
        case .frozen:       return "🧊"
        case .beverages:    return "🥤"
        case .snacks:       return "🍪"
        case .pantry:       return "🫙"
        case .household:    return "🧹"
        case .personalCare: return "🧴"
        case .other:        return "📦"
        }
    }

    var sortOrder: Int {
        switch self {
        case .produce: return 0
        case .dairy: return 1
        case .meat: return 2
        case .bakery: return 3
        case .frozen: return 4
        case .beverages: return 5
        case .snacks: return 6
        case .pantry: return 7
        case .household: return 8
        case .personalCare: return 9
        case .other: return 10
        }
    }
}

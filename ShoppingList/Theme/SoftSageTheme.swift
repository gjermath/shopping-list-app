import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(red: 0.98, green: 0.99, blue: 0.976)       // #FAFDF9
    static let primaryGreen = Color(red: 0.18, green: 0.49, blue: 0.196)     // #2E7D32
    static let secondaryGreen = Color(red: 0.506, green: 0.78, blue: 0.518)  // #81C784
    static let flagAmber = Color(red: 1.0, green: 0.702, blue: 0.0)          // #FFB300
    static let surfaceWhite = Color.white
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)       // #212121
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)        // #999999
    static let divider = Color(red: 0.93, green: 0.93, blue: 0.93)           // #EDEDED

    // MARK: - Category Colors
    static func categoryColor(_ category: String) -> Color {
        switch category {
        case "Produce":       return Color(red: 0.945, green: 0.973, blue: 0.914) // #F1F8E9
        case "Dairy":         return Color(red: 0.89, green: 0.949, blue: 0.992)  // #E3F2FD
        case "Meat":          return Color(red: 0.988, green: 0.894, blue: 0.882) // #FCE4E2
        case "Bakery":        return Color(red: 1.0, green: 0.953, blue: 0.878)   // #FFF3E0
        case "Frozen":        return Color(red: 0.882, green: 0.961, blue: 0.996) // #E1F5FE
        case "Beverages":     return Color(red: 0.914, green: 0.906, blue: 0.965) // #E9E7F6
        case "Snacks":        return Color(red: 1.0, green: 0.965, blue: 0.886)   // #FFF6E2
        case "Pantry":        return Color(red: 0.937, green: 0.922, blue: 0.882) // #EFEBE1
        case "Household":     return Color(red: 0.914, green: 0.941, blue: 0.945) // #E9F0F2
        case "Personal Care": return Color(red: 0.969, green: 0.914, blue: 0.957) // #F7E9F4
        default:              return Color(red: 0.961, green: 0.961, blue: 0.961) // #F5F5F5
        }
    }

    static func categoryTextColor(_ category: String) -> Color {
        switch category {
        case "Produce":       return Color(red: 0.337, green: 0.545, blue: 0.184) // #558B2F
        case "Dairy":         return Color(red: 0.082, green: 0.396, blue: 0.753) // #1565C0
        case "Meat":          return Color(red: 0.776, green: 0.157, blue: 0.157) // #C62828
        case "Bakery":        return Color(red: 0.929, green: 0.424, blue: 0.0)   // #EF6C00
        case "Frozen":        return Color(red: 0.012, green: 0.388, blue: 0.616) // #0363B8
        case "Beverages":     return Color(red: 0.369, green: 0.208, blue: 0.694) // #5E35B1
        case "Snacks":        return Color(red: 0.698, green: 0.494, blue: 0.0)   // #B27E00
        case "Pantry":        return Color(red: 0.427, green: 0.349, blue: 0.196) // #6D5932
        case "Household":     return Color(red: 0.263, green: 0.388, blue: 0.424) // #43636C
        case "Personal Care": return Color(red: 0.533, green: 0.176, blue: 0.455) // #882D74
        default:              return Color(red: 0.459, green: 0.459, blue: 0.459) // #757575
        }
    }

    // MARK: - Typography
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 14
    static let cardShadow: CGFloat = 4
}

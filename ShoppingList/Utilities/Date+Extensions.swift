import Foundation

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var isOlderThan24Hours: Bool {
        timeIntervalSinceNow < -86400
    }
}

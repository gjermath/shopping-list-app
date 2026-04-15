import Foundation

class InviteService {
    func generateInviteLink(inviteCode: String, listName: String) -> URL? {
        // Simple URL scheme for sharing invite codes
        // In production, this would be a universal link (e.g., https://yourapp.com/invite?code=...)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "shoppinglist.app"
        components.path = "/invite"
        components.queryItems = [
            URLQueryItem(name: "code", value: inviteCode)
        ]
        return components.url
    }

    func extractInviteCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }
}

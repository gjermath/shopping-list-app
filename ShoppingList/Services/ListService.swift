import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ListService: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var isLoading = true

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[ListService] No authenticated user, skipping listener")
            return
        }

        print("[ListService] Starting listener for user: \(userId)")

        listener = db.collection("lists")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[ListService] Listener error: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("[ListService] No documents in snapshot")
                    return
                }
                print("[ListService] Received \(documents.count) lists")
                self?.lists = documents.compactMap { doc in
                    var list = try? doc.data(as: ShoppingList.self)
                    list?.currentUserId = userId
                    return list
                }
                self?.isLoading = false
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func createList(name: String) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ListServiceError.notAuthenticated
        }

        let inviteCode = UUID().uuidString.prefix(8).lowercased()
        let list = ShoppingList(
            name: name,
            ownerId: userId,
            memberIds: [userId],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: String(inviteCode)
        )

        let docRef = try db.collection("lists").addDocument(from: list)
        return docRef.documentID
    }

    func updateListName(_ listId: String, name: String) async throws {
        try await db.collection("lists").document(listId).updateData([
            "name": name,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func deleteList(_ listId: String) async throws {
        try await db.collection("lists").document(listId).delete()
    }

    func leaveList(_ listId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("lists").document(listId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }

    func joinList(inviteCode: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let snapshot = try await db.collection("lists")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            throw ListServiceError.inviteNotFound
        }

        let existingMembers = doc.data()["memberIds"] as? [String] ?? []
        if existingMembers.contains(userId) {
            throw ListServiceError.alreadyMember
        }

        try await doc.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }

    func removeMember(_ listId: String, userId: String) async throws {
        try await db.collection("lists").document(listId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }

    // MARK: - Static helpers for App Intents

    static func fetchLists(for userId: String) async throws -> [ShoppingList] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("lists")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var list = try? doc.data(as: ShoppingList.self)
            list?.currentUserId = userId
            return list
        }
    }

    static func fetchUserDefaultListId(for userId: String) async throws -> String? {
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(userId).getDocument()
        return doc.data()?["defaultListId"] as? String
    }
}

enum ListServiceError: LocalizedError {
    case notAuthenticated
    case inviteNotFound
    case alreadyMember

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return String(localized: "You must be signed in.")
        case .inviteNotFound: return String(localized: "Invite link not found or expired.")
        case .alreadyMember: return String(localized: "You're already a member of this list.")
        }
    }
}

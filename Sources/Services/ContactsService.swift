import Foundation
import Contacts

@MainActor
class ContactsService: ObservableObject {
    @Published var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

    // Shared instance — Apple recommends reusing the store rather than
    // creating a new one per fetch. A fresh instance can silently return
    // zero contacts on macOS even when access is already authorized.
    private let store = CNContactStore()

    private static let fetchKeys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactNicknameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactImageDataAvailableKey as CNKeyDescriptor,
    ]

    // Always call this on launch regardless of current status.
    // Even when already authorized, the call initialises the store's
    // connection to the Contacts daemon on macOS.
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return granted
        } catch {
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return false
        }
    }

    // Runs on a background thread so the blocking enumerateContacts call
    // does not stall the MainActor.
    func fetchContacts() async throws -> [CNContact] {
        let store = self.store
        let keys = Self.fetchKeys
        return try await Task.detached(priority: .userInitiated) {
            var contacts: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: keys)
            try store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
            return contacts
        }.value
    }

    func apply(_ updates: [ContactUpdate]) throws {
        let saveRequest = CNSaveRequest()
        var hasChanges = false

        for update in updates where update.isApproved {
            let mutable = update.contact.mutableCopy() as! CNMutableContact
            var changed = false

            if update.applyTitle && update.hasTitleChange {
                mutable.jobTitle = update.proposedTitle
                changed = true
            }
            if update.applyCompany && update.hasCompanyChange {
                mutable.organizationName = update.proposedCompany
                changed = true
            }
            if update.applyPhoto, let data = update.photoData {
                mutable.imageData = data
                changed = true
            }

            if changed {
                saveRequest.update(mutable)
                hasChanges = true
            }
        }

        if hasChanges {
            try store.execute(saveRequest)
        }
    }
}

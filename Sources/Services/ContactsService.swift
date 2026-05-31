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

    // Fetches contacts from every container (local, iCloud, CardDAV…).
    // Creates its own CNContactStore on the background thread — sharing the
    // MainActor store across threads can cause silent empty results.
    func fetchContacts() async throws -> (contacts: [CNContact], containerCount: Int) {
        let keys = Self.fetchKeys
        return try await Task.detached(priority: .userInitiated) {
            let bgStore = CNContactStore()
            let containers = try bgStore.containers(matching: nil)
            var contacts: [CNContact] = []
            for container in containers {
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                let batch = try bgStore.unifiedContacts(matching: predicate, keysToFetch: keys)
                contacts.append(contentsOf: batch)
            }
            var seen = Set<String>()
            let deduped = contacts.filter { seen.insert($0.identifier).inserted }
            return (deduped, containers.count)
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

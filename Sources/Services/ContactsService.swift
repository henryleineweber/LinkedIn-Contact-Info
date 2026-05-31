import Foundation
import Contacts

@MainActor
class ContactsService: ObservableObject {
    @Published var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

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

    func requestAccess() async -> Bool {
        do {
            let granted = try await CNContactStore().requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return granted
        } catch {
            return false
        }
    }

    func fetchContacts() throws -> [CNContact] {
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: Self.fetchKeys)
        try CNContactStore().enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }

    func apply(_ updates: [ContactUpdate]) throws {
        let store = CNContactStore()
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

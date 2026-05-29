import Foundation
import Contacts

struct ContactUpdate: Identifiable {
    let id = UUID()
    let contact: CNContact
    let connection: LinkedInConnection
    var photoData: Data?
    var isApproved: Bool = true
    var applyTitle: Bool = true
    var applyCompany: Bool = true
    var applyPhoto: Bool = true

    var proposedTitle: String { connection.position }
    var proposedCompany: String { connection.company }
    var currentTitle: String { contact.jobTitle }
    var currentCompany: String { contact.organizationName }

    var hasTitleChange: Bool {
        !proposedTitle.isEmpty && proposedTitle != currentTitle
    }
    var hasCompanyChange: Bool {
        !proposedCompany.isEmpty && proposedCompany != currentCompany
    }
    var hasPhotoChange: Bool { photoData != nil }
    var hasChanges: Bool { hasTitleChange || hasCompanyChange || hasPhotoChange }
}

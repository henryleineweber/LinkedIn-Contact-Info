import Foundation

struct LinkedInConnection: Identifiable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let emailAddress: String
    let company: String
    let position: String

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

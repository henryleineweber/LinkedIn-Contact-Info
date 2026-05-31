import Foundation

// MARK: - OAuth token response

struct TokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Localized name field  {"localized":{"en_US":"John"},"preferredLocale":{"language":"en","country":"US"}}

struct MultiLocale: Decodable {
    private let localized: [String: String]
    private let preferredLocale: PreferredLocale?

    var value: String {
        if let key = preferredLocale?.key, let v = localized[key] { return v }
        return localized.values.first ?? ""
    }

    private struct PreferredLocale: Decodable {
        let language: String
        let country: String
        var key: String { "\(language)_\(country)" }
    }
}

// MARK: - Profile picture  (displayImage~ with nested identifiers)

struct ProfilePicture: Decodable {
    let photoURL: URL?

    private enum CodingKeys: String, CodingKey {
        case display = "displayImage~"
    }

    private struct Display: Decodable {
        let elements: [Element]

        struct Element: Decodable {
            let identifiers: [Identifier]

            struct Identifier: Decodable {
                let identifier: String
                let identifierType: String
            }
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let display = try? c.decode(Display.self, forKey: .display)
        // Elements are in ascending resolution order; last = largest
        photoURL = display?.elements
            .flatMap { $0.identifiers }
            .filter { $0.identifierType == "EXTERNAL_URL" }
            .compactMap { URL(string: $0.identifier) }
            .last
    }
}

// MARK: - Connection profile element

struct ProfileElement: Decodable {
    let id: String
    let firstName: MultiLocale
    let lastName: MultiLocale
    let headline: MultiLocale?
    let profilePicture: ProfilePicture?
}

// MARK: - Paginated connections response

struct ConnectionsResponse: Decodable {
    let elements: [ProfileElement]
    let paging: Paging

    struct Paging: Decodable {
        let count: Int
        let start: Int
        let total: Int
    }
}

import Foundation

struct LinkedInAPIService {
    let accessToken: String

    private static let baseURL = "https://api.linkedin.com/v2"

    // Returns connections paired with their profile photo URL (if available).
    // Paginates automatically until all connections are fetched.
    func fetchConnections() async throws -> [(connection: LinkedInConnection, photoURL: URL?)] {
        var results: [(LinkedInConnection, URL?)] = []
        var start = 0
        let count = 50
        let projection = "(elements*(id,firstName,lastName,headline,profilePicture(displayImage~:playableStreams)),paging)"

        repeat {
            var components = URLComponents(string: "\(Self.baseURL)/connections")!
            components.queryItems = [
                URLQueryItem(name: "q", value: "viewer"),
                URLQueryItem(name: "start", value: String(start)),
                URLQueryItem(name: "count", value: String(count)),
                URLQueryItem(name: "projection", value: projection),
            ]

            let data = try await get(components.url!)
            let page = try JSONDecoder().decode(ConnectionsResponse.self, from: data)

            for element in page.elements {
                let headline = element.headline?.value ?? ""
                let (position, company) = parseHeadline(headline)
                let connection = LinkedInConnection(
                    firstName: element.firstName.value,
                    lastName: element.lastName.value,
                    emailAddress: "",
                    company: company,
                    position: position
                )
                results.append((connection, element.profilePicture?.photoURL))
            }

            start += count
            if page.elements.count < count || results.count >= page.paging.total { break }
        } while true

        return results
    }

    func downloadPhoto(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // Splits "Senior Engineer at Acme Corp" → ("Senior Engineer", "Acme Corp")
    private func parseHeadline(_ headline: String) -> (position: String, company: String) {
        for separator in [" at ", " | ", " @ ", " · "] {
            if let range = headline.range(of: separator, options: .caseInsensitive) {
                let position = String(headline[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let company = String(headline[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !position.isEmpty && !company.isEmpty { return (position, company) }
            }
        }
        return (headline.trimmingCharacters(in: .whitespaces), "")
    }

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2.0.0", forHTTPHeaderField: "X-Restli-Protocol-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        switch http.statusCode {
        case 200: return data
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(http.statusCode, body)
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse, unauthorized, forbidden, httpError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from LinkedIn API."
            case .unauthorized:
                return "LinkedIn session expired. Please sign in again."
            case .forbidden:
                return "LinkedIn API access denied (403). The 'r_network' permission is required. See README for LinkedIn developer app setup."
            case .httpError(let code, let body):
                return "LinkedIn API error \(code): \(body.prefix(200))"
            }
        }
    }
}

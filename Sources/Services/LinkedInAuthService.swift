import AuthenticationServices
import Foundation

@MainActor
class LinkedInAuthService: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false

    // Stored in UserDefaults — acceptable for a personal developer tool.
    // For a distributed app, move clientSecret to Keychain.
    @Published var clientId: String = UserDefaults.standard.string(forKey: "linkedin_client_id") ?? "" {
        didSet { UserDefaults.standard.set(clientId, forKey: "linkedin_client_id") }
    }
    @Published var clientSecret: String = UserDefaults.standard.string(forKey: "linkedin_client_secret") ?? "" {
        didSet { UserDefaults.standard.set(clientSecret, forKey: "linkedin_client_secret") }
    }

    private(set) var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "linkedin_access_token") }
        set {
            UserDefaults.standard.set(newValue, forKey: "linkedin_access_token")
            isAuthenticated = newValue != nil
        }
    }

    var hasCredentials: Bool { !clientId.isEmpty && !clientSecret.isEmpty }

    static let redirectURI = "linkedincontactsync://oauth/callback"
    private static let scopes = "r_liteprofile r_emailaddress r_network"

    override init() {
        super.init()
        isAuthenticated = UserDefaults.standard.string(forKey: "linkedin_access_token") != nil
    }

    func authenticate() async throws {
        guard hasCredentials else { throw AuthError.missingCredentials }

        var components = URLComponents(string: "https://www.linkedin.com/oauth/v2/authorization")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "scope", value: Self.scopes),
            URLQueryItem(name: "state", value: UUID().uuidString),
        ]

        let code = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(
                url: components.url!,
                callbackURLScheme: "linkedincontactsync"
            ) { callbackURL, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                guard let url = callbackURL,
                      let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    cont.resume(throwing: AuthError.noCode)
                    return
                }
                cont.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        accessToken = try await exchangeCode(code)
    }

    func signOut() {
        accessToken = nil
    }

    private func exchangeCode(_ code: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://www.linkedin.com/oauth/v2/accessToken")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectURI,
            "client_id": clientId,
            "client_secret": clientSecret,
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data).accessToken
    }

    enum AuthError: LocalizedError {
        case missingCredentials, noCode, tokenExchangeFailed
        var errorDescription: String? {
            switch self {
            case .missingCredentials: return "Enter your LinkedIn Client ID and Client Secret first."
            case .noCode: return "Authorization was cancelled or no code was returned."
            case .tokenExchangeFailed: return "Failed to exchange authorization code for access token. Check your Client Secret."
            }
        }
    }
}

extension LinkedInAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        DispatchQueue.main.sync {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
        }
        #else
        DispatchQueue.main.sync {
            NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
        }
        #endif
    }
}

import SwiftUI

struct CredentialsView: View {
    @ObservedObject var authService: LinkedInAuthService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Client ID", text: $authService.clientId)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    SecureField("Client Secret", text: $authService.clientSecret)
                } header: {
                    Text("LinkedIn Developer App")
                } footer: {
                    Text("Create an app at developer.linkedin.com. Set the redirect URL to:\n\(LinkedInAuthService.redirectURI)")
                        .font(.caption)
                }

                Section("Required permissions") {
                    PermissionRow(name: "r_liteprofile", description: "Name and profile photo")
                    PermissionRow(name: "r_emailaddress", description: "Email address")
                    PermissionRow(name: "r_network", description: "First-degree connections")
                }

                Section {
                    Link("Open LinkedIn Developer Portal",
                         destination: URL(string: "https://developer.linkedin.com")!)
                }
            }
            .navigationTitle("Credentials")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(!authService.hasCredentials)
                }
            }
        }
    }
}

private struct PermissionRow: View {
    let name: String
    let description: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(.body, design: .monospaced))
            Spacer()
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

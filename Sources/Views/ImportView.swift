import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @ObservedObject var authService: LinkedInAuthService
    let onFetchFromAPI: () async -> Void
    let onImportCSV: (URL, URL?) async -> Void

    @State private var showCredentials = false
    @State private var showCSVPicker = false
    @State private var showFolderPicker = false
    @State private var csvURL: URL?
    @State private var photoFolderURL: URL?
    @State private var isAuthenticating = false
    @State private var authError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                Image(systemName: "person.2.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("LinkedIn Contact Sync")
                        .font(.title.bold())
                    Text("Sync job titles, companies, and photos\nfrom LinkedIn into your Contacts app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // MARK: Primary: LinkedIn API
                apiSection

                Divider().padding(.horizontal)

                // MARK: Fallback: CSV import
                csvSection

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("Import")
        .sheet(isPresented: $showCredentials) {
            CredentialsView(authService: authService)
        }
        .fileImporter(isPresented: $showCSVPicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            csvURL = try? result.get()
        }
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            photoFolderURL = try? result.get()
        }
        .alert("Sign-in Error", isPresented: Binding(
            get: { authError != nil },
            set: { if !$0 { authError = nil } }
        )) {
            Button("OK") { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    // MARK: - API section

    private var apiSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Via LinkedIn API")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Configure") { showCredentials = true }
                    .font(.subheadline)
            }
            .padding(.horizontal)

            if authService.isAuthenticated {
                Button {
                    Task { await onFetchFromAPI() }
                } label: {
                    Label("Fetch My Connections", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)

                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.footnote)
                }
            } else {
                StatusCard(
                    icon: authService.hasCredentials ? "checkmark.circle" : "exclamationmark.circle",
                    text: authService.hasCredentials ? "Credentials configured" : "No credentials — tap Configure",
                    tint: authService.hasCredentials ? .green : .orange
                )
                .padding(.horizontal)

                Button {
                    guard authService.hasCredentials else { showCredentials = true; return }
                    isAuthenticating = true
                    Task {
                        defer { isAuthenticating = false }
                        do { try await authService.authenticate() }
                        catch { authError = error.localizedDescription }
                    }
                } label: {
                    Group {
                        if isAuthenticating {
                            ProgressView().tint(.white)
                        } else {
                            Label("Sign in with LinkedIn", systemImage: "person.badge.key")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isAuthenticating)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - CSV section

    private var csvSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Via CSV Export (no API needed)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                PickerCard(
                    title: "LinkedIn Export CSV",
                    detail: csvURL?.lastPathComponent ?? "No file selected",
                    icon: "doc.text.fill",
                    isSet: csvURL != nil,
                    action: { showCSVPicker = true }
                )
                PickerCard(
                    title: "Photos Folder  (optional)",
                    detail: photoFolderURL?.lastPathComponent ?? "No folder selected",
                    icon: "folder.fill",
                    isSet: photoFolderURL != nil,
                    action: { showFolderPicker = true }
                )
            }
            .padding(.horizontal)

            Button {
                guard let url = csvURL else { return }
                Task { await onImportCSV(url, photoFolderURL) }
            } label: {
                Label("Import CSV", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(csvURL == nil)
            .padding(.horizontal)

            Text("LinkedIn → Settings → Data privacy → Get a copy of your data → Connections")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct StatusCard: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PickerCard: View {
    let title: String
    let detail: String
    let icon: String
    let isSet: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSet ? .blue : .secondary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Image(systemName: isSet ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isSet ? .green : .quaternary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

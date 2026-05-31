import SwiftUI
import Contacts

struct ContentView: View {
    @StateObject private var contactsService = ContactsService()
    @State private var updates: [ContactUpdate] = []
    @State private var phase: Phase = .import
    @State private var isWorking = false
    @State private var errorMessage: String?

    enum Phase { case `import`, review, done }

    var body: some View {
        NavigationStack {
            switch phase {
            case .import:
                ImportView { csvURL, photoFolderURL in
                    await loadUpdates(csvURL: csvURL, photoFolderURL: photoFolderURL)
                }
            case .review:
                ReviewView(updates: $updates, onApply: { await commitChanges() }, onBack: { phase = .import })
            case .done:
                DoneView(appliedCount: updates.filter(\.isApproved).count) {
                    updates = []
                    phase = .import
                }
            }
        }
        .overlay { if isWorking { WorkingOverlay() } }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            // Always call even if already authorized — initialises the
            // store's connection to the Contacts daemon on macOS.
            _ = await contactsService.requestAccess()
        }
    }

    private func loadUpdates(csvURL: URL, photoFolderURL: URL?) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let connections = try LinkedInImporter.parse(url: csvURL)
            guard !connections.isEmpty else {
                errorMessage = "No connections found in the CSV. Make sure you selected the Connections.csv file from your LinkedIn data export."
                return
            }

            let contacts = try await contactsService.fetchContacts()
            guard !contacts.isEmpty else {
                let status = CNContactStore.authorizationStatus(for: .contacts)
                errorMessage = "Contacts returned 0 entries (auth status: \(status.rawValue)). If status is 3 the permission is granted but no contacts were found — make sure your Mac's Contacts app has finished syncing with iCloud."
                return
            }

            let matches = MatchingService.match(connections: connections, against: contacts)
            guard !matches.isEmpty else {
                let sample = connections.prefix(3).map { "\($0.firstName) \($0.lastName)" }.joined(separator: ", ")
                errorMessage = "Parsed \(connections.count) LinkedIn connections, found \(contacts.count) contacts, but nothing matched.\n\nSample LinkedIn names: \(sample)\n\nCheck that names on LinkedIn match how they're stored in your Contacts app."
                return
            }

            var result = matches.map { ContactUpdate(contact: $0.contact, connection: $0.connection) }

            if let folder = photoFolderURL {
                _ = folder.startAccessingSecurityScopedResource()
                defer { folder.stopAccessingSecurityScopedResource() }
                for i in result.indices {
                    result[i].photoData = loadPhoto(for: result[i].connection, from: folder)
                }
            }

            updates = result.filter(\.hasChanges)
            phase = .review
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commitChanges() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try contactsService.apply(updates)
            phase = .done
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPhoto(for connection: LinkedInConnection, from folder: URL) -> Data? {
        let names = [
            connection.fullName,
            "\(connection.lastName), \(connection.firstName)",
        ]
        let exts = ["jpg", "jpeg", "png", "heic", "heif"]
        for name in names {
            for ext in exts {
                let url = folder.appendingPathComponent("\(name).\(ext)")
                if let data = try? Data(contentsOf: url) { return data }
            }
        }
        return nil
    }
}

struct WorkingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView("Working…")
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

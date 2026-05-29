import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    let onImport: (URL, URL?) async -> Void

    @State private var csvURL: URL?
    @State private var photoFolderURL: URL?
    @State private var showCSVPicker = false
    @State private var showFolderPicker = false

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
                    Text("Import your LinkedIn connections export to review\nupdates for job titles, companies, and photos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
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
                    Task { await onImport(url, photoFolderURL) }
                } label: {
                    Label("Find Matching Contacts", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(csvURL == nil)
                .padding(.horizontal)

                Text("Export from LinkedIn: Settings → Data privacy →\nGet a copy of your data → Connections")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("Import")
        .fileImporter(
            isPresented: $showCSVPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            csvURL = try? result.get()
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            photoFolderURL = try? result.get()
        }
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

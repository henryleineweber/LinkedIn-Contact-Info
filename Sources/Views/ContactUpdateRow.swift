import SwiftUI
import Contacts

struct ContactUpdateRow: View {
    @Binding var update: ContactUpdate

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ContactAvatar(
                contact: update.contact,
                proposedPhotoData: (update.applyPhoto && update.isApproved) ? update.photoData : nil
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(update.contact.fullName)
                    .font(.headline)

                if update.hasTitleChange {
                    FieldChangeRow(
                        icon: "briefcase.fill",
                        current: update.currentTitle,
                        proposed: update.proposedTitle,
                        isOn: $update.applyTitle,
                        parentApproved: update.isApproved
                    )
                }

                if update.hasCompanyChange {
                    FieldChangeRow(
                        icon: "building.2.fill",
                        current: update.currentCompany,
                        proposed: update.proposedCompany,
                        isOn: $update.applyCompany,
                        parentApproved: update.isApproved
                    )
                }

                if update.hasPhotoChange {
                    FieldChangeRow(
                        icon: "photo.fill",
                        current: update.contact.imageDataAvailable ? "Current photo" : "No photo",
                        proposed: "LinkedIn photo",
                        isOn: $update.applyPhoto,
                        parentApproved: update.isApproved
                    )
                }
            }

            Spacer()

            Toggle("Approved", isOn: $update.isApproved)
                .labelsHidden()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .opacity(update.isApproved ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.15), value: update.isApproved)
    }
}

struct FieldChangeRow: View {
    let icon: String
    let current: String
    let proposed: String
    @Binding var isOn: Bool
    let parentApproved: Bool

    private var active: Bool { isOn && parentApproved }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                if !current.isEmpty {
                    Text(current)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .strikethrough(active, color: .secondary)
                }
                Text(proposed)
                    .font(.caption)
                    .fontWeight(active ? .semibold : .regular)
                    .foregroundStyle(active ? Color.green : .primary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.75)
                .disabled(!parentApproved)
        }
    }
}

struct ContactAvatar: View {
    let contact: CNContact
    let proposedPhotoData: Data?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.2))

            if let data = proposedPhotoData ?? contact.imageData, let img = image(from: data) {
                img.resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
    }

    private func image(from data: Data) -> Image? {
        #if canImport(UIKit)
        return UIImage(data: data).map(Image.init)
        #else
        return NSImage(data: data).map(Image.init)
        #endif
    }
}

extension CNContact {
    var fullName: String {
        [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

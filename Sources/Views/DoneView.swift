import SwiftUI

struct DoneView: View {
    let appliedCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("All Done!")
                    .font(.title.bold())
                Text(appliedCount == 0
                     ? "No changes were applied."
                     : "\(appliedCount) contact\(appliedCount == 1 ? "" : "s") updated successfully.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Start Over", action: onDone)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .navigationTitle("Complete")
    }
}

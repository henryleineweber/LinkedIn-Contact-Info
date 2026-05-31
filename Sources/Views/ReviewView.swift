import SwiftUI

struct ReviewView: View {
    @Binding var updates: [ContactUpdate]
    let onApply: () async -> Void
    let onBack: () -> Void

    private var approvedCount: Int { updates.filter(\.isApproved).count }

    var body: some View {
        Group {
            if updates.isEmpty {
                emptyState
            } else {
                List {
                    ForEach($updates) { $update in
                        ContactUpdateRow(update: $update)
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Review Changes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back", action: onBack)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Approve All") {
                        updates.indices.forEach { updates[$0].isApproved = true }
                    }
                    Button("Reject All") {
                        updates.indices.forEach { updates[$0].isApproved = false }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !updates.isEmpty { applyBar }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("No Changes Found")
                .font(.title2.bold())
            Text("All matched contacts already have the same job title and company as LinkedIn.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var applyBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text(approvedCount == 0
                     ? "No changes selected"
                     : "\(approvedCount) contact\(approvedCount == 1 ? "" : "s") to update")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await onApply() }
                } label: {
                    Text("Apply Changes")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(approvedCount == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

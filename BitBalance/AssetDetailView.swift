import SwiftUI

struct AssetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let asset: Asset

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(asset.symbol)
                .font(.largeTitle)
                .bold()

            Group {
                HStack { Text("Quantity"); Spacer(); Text("\(asset.quantity, specifier: "%.4f")") }
                HStack { Text("Last Price"); Spacer(); Text("$\(asset.lastPrice, specifier: "%.2f")") }
                HStack { Text("Value"); Spacer(); Text("$\(asset.value, specifier: "%.2f")").bold() }
            }
            .font(.title3)

            Spacer()

            HStack(spacing: 12) {
                NavigationLink {
                    AddEditAssetView()
                } label: {
                    Text("Edit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Asset Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Asset?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                // UI milestone: just dismiss for now
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This is a UI-only action for the milestone.")
        }
    }
}

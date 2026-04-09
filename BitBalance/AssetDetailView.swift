import SwiftUI

struct AssetDetailView: View {
    @EnvironmentObject private var assetStore: AssetStore
    @Environment(\.dismiss) private var dismiss
    let assetID: UUID

    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if let asset = assetStore.asset(withID: assetID) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(asset.symbol)
                        .font(.largeTitle)
                        .bold()

                    if let marketDataMessage = assetStore.marketDataMessage {
                        Text(marketDataMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Group {
                        HStack { Text("Category"); Spacer(); Text(asset.category.rawValue) }
                        HStack { Text("Quantity"); Spacer(); Text("\(asset.quantity, specifier: "%.4f")") }
                        HStack { Text("Current Price"); Spacer(); Text("$\(asset.lastPrice, specifier: "%.2f")") }
                        HStack { Text("Value"); Spacer(); Text("$\(asset.value, specifier: "%.2f")").bold() }
                    }
                    .font(.title3)

                    Spacer()

                    HStack(spacing: 12) {
                        NavigationLink {
                            AddEditAssetView(asset: asset)
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
            } else {
                ContentUnavailableView("Asset Not Found", systemImage: "tray")
            }
        }
        .navigationTitle("Asset Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await assetStore.refreshPrices(for: [assetID], trigger: "asset detail manual refresh")
                    }
                } label: {
                    if assetStore.isRefreshingPrices {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(assetStore.isRefreshingPrices)
            }
        }
        .task {
            await assetStore.refreshPrices(for: [assetID], trigger: "asset detail appeared")
        }
        .alert("Delete Asset?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                assetStore.deleteAsset(id: assetID)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This asset will be removed from your portfolio.")
        }
    }
}

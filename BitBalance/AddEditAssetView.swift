import SwiftUI

struct AddEditAssetView: View {
    @EnvironmentObject private var assetStore: AssetStore
    @Environment(\.dismiss) private var dismiss

    let asset: Asset?

    @State private var symbol: String
    @State private var quantity: String
    @State private var lastPrice: String
    @State private var category: NetWorthCategory

    init(asset: Asset? = nil) {
        self.asset = asset
        _symbol = State(initialValue: asset?.symbol ?? "")
        _quantity = State(initialValue: asset.map { String($0.quantity) } ?? "")
        _lastPrice = State(initialValue: asset.map { String($0.lastPrice) } ?? "")
        _category = State(initialValue: asset?.category ?? .crypto)
    }

    private var isEditing: Bool {
        asset != nil
    }

    private var canSave: Bool {
        !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(quantity) != nil &&
        (requiresManualPrice ? Double(lastPrice) != nil : true)
    }

    private var requiresManualPrice: Bool {
        category == .realEstate || category == .vehicles || category == .others
    }

    var body: some View {
        Form {
            Section(header: Text("Asset Info")) {
                TextField("Symbol (e.g., BTC)", text: $symbol)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)

                TextField(requiresManualPrice ? "Current Price" : "Fallback Price (used until live quote loads)", text: $lastPrice)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $category) {
                    ForEach(NetWorthCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            Section {
                Button("Save") {
                    saveAsset()
                }
                .disabled(!canSave)

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Asset" : "Add Asset")
    }

    private func saveAsset() {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard
            let parsedQuantity = Double(quantity)
        else {
            return
        }

        let parsedLastPrice = Double(lastPrice) ?? 0

        if let asset {
            assetStore.updateAsset(
                id: asset.id,
                symbol: trimmedSymbol,
                quantity: parsedQuantity,
                lastPrice: parsedLastPrice,
                category: category
            )
        } else {
            assetStore.addAsset(
                symbol: trimmedSymbol,
                quantity: parsedQuantity,
                lastPrice: parsedLastPrice,
                category: category
            )
        }

        dismiss()
    }
}

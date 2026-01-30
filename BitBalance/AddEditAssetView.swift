import SwiftUI

struct AddEditAssetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var symbol: String = ""
    @State private var quantity: String = ""

    var body: some View {
        Form {
            Section(header: Text("Asset Info")) {
                TextField("Symbol (e.g., BTC)", text: $symbol)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button("Save") {
                    // UI milestone: no persistence needed yet
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Add Asset")
    }
}

import SwiftUI

struct Asset: Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Double
    let lastPrice: Double

    var value: Double { quantity * lastPrice }
}

struct ContentView: View {
    @State private var assets: [Asset] = [
        Asset(symbol: "BTC", quantity: 0.25, lastPrice: 60000),
        Asset(symbol: "ETH", quantity: 2.0, lastPrice: 2500),
        Asset(symbol: "AAPL", quantity: 10, lastPrice: 190)
    ]

    private var totalValue: Double {
        assets.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Total Value")
                    .font(.headline)

                Text("$\(totalValue, specifier: "%.2f")")
                    .font(.largeTitle)
                    .bold()

                List {
                    Section(header: Text("Assets")) {
                        ForEach(assets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(asset.symbol).font(.headline)
                                        Text("Qty: \(asset.quantity, specifier: "%.4f")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("$\(asset.value, specifier: "%.2f")")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding(.top, 12)
            .navigationTitle("BitBalance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddEditAssetView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

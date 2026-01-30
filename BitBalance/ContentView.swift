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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // NET WORTH CARD
                    NeonCard(title: "Net Worth") {
                        Text("$\(totalValue, specifier: "%.2f")")
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("Demo values (UI milestone)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    // ASSETS CARD
                    NeonCard(title: "Assets") {
                        ForEach(assets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(asset.symbol)
                                            .font(.system(.headline, design: .monospaced))
                                            .foregroundStyle(.white)

                                        Text("Qty: \(asset.quantity, specifier: "%.4f")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("$\(asset.value, specifier: "%.2f")")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(FuturisticTheme.good)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            Divider().opacity(0.25)
                        }
                    }

                    Spacer(minLength: 10)
                }
                .padding()
            }
            .background(FuturisticTheme.bg.ignoresSafeArea())
            .navigationTitle("BitBalance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddEditAssetView()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(FuturisticTheme.accent)
                    }
                }
            }
        }
    }
}


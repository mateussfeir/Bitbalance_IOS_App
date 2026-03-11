import SwiftUI

// MARK: - Models

enum NetWorthCategory: String, CaseIterable, Identifiable {
    case realEstate = "Real Estate"
    case crypto = "Crypto"
    case stocks = "Stocks"
    case vehicles = "Vehicles"
    case others = "Others"

    var id: String { rawValue }
}

struct CategorySummary: Identifiable {
    let id = UUID()
    let category: NetWorthCategory
    let totalValue: Double
}

// MARK: - Main View

struct ContentView: View {

    // REAL PORTFOLIO DATA
    @State private var assets: [Asset] = [
        Asset(symbol: "BTC", quantity: 1.2, lastPrice: 60000, category: .crypto),
        Asset(symbol: "ETH", quantity: 5, lastPrice: 3000, category: .crypto),
        Asset(symbol: "AAPL", quantity: 50, lastPrice: 190, category: .stocks),
        Asset(symbol: "TSLA", quantity: 20, lastPrice: 250, category: .stocks),
        Asset(symbol: "Toronto Condo", quantity: 1, lastPrice: 170000, category: .realEstate),
        Asset(symbol: "Car", quantity: 1, lastPrice: 38500, category: .vehicles),
        Asset(symbol: "Cash Savings", quantity: 1, lastPrice: 19200, category: .others)
    ]

    // CATEGORY TOTALS CALCULATED FROM ASSETS
    private var categories: [CategorySummary] {
        NetWorthCategory.allCases.map { category in
            let total = assets
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.value }

            return CategorySummary(category: category, totalValue: total)
        }
    }

    private var totalNetWorth: Double {
        assets.reduce(0) { $0 + $1.value }
    }

    private func percent(for value: Double) -> Double {
        guard totalNetWorth > 0 else { return 0 }
        return (value / totalNetWorth) * 100
    }

    private func destinationView(for category: NetWorthCategory) -> AnyView {

        let filteredAssets = assets.filter { $0.category == category }

        switch category {
        case .crypto:
            return AnyView(AssetListView(title: "Crypto", assets: filteredAssets))

        case .stocks:
            return AnyView(AssetListView(title: "Stocks", assets: filteredAssets))

        case .realEstate:
            return AnyView(AssetListView(title: "Real Estate", assets: filteredAssets))

        case .vehicles:
            return AnyView(AssetListView(title: "Vehicles", assets: filteredAssets))

        case .others:
            return AnyView(AssetListView(title: "Others", assets: filteredAssets))
        }
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    // NET WORTH CARD
                    NeonCard(title: nil) {

                        HStack(alignment: .firstTextBaseline) {

                            Text("NET WORTH")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(FuturisticTheme.accent)

                            Spacer()

                            Text("$\(totalNetWorth, specifier: "%.2f")")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(FuturisticTheme.good)
                        }
                    }

                    // CATEGORY TABLE
                    NeonCard(title: "Net Worth Composition") {

                        HStack {

                            Text("TYPE")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("TOTAL")
                                .frame(width: 140, alignment: .trailing)

                            Text("%")
                                .frame(width: 70, alignment: .trailing)
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(FuturisticTheme.accent)
                        .padding(.bottom, 6)

                        Divider().opacity(0.25)

                        ForEach(categories) { item in

                            NavigationLink {

                                destinationView(for: item.category)

                            } label: {

                                HStack {

                                    Text(item.category.rawValue)
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("$\(item.totalValue, specifier: "%.2f")")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .frame(width: 140, alignment: .trailing)

                                    Text("\(percent(for: item.totalValue), specifier: "%.2f")%")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(FuturisticTheme.good)
                                        .frame(width: 70, alignment: .trailing)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            Divider().opacity(0.18)
                        }
                    }

                    // PIE CHART (still dummy for prototype)
                    NeonCard(title: "Composition Pie") {

                        Text("Pie chart uses dummy data for now.")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)

                        DummyPieChart()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FuturisticTheme.border, lineWidth: 1)
                                    .shadow(color: FuturisticTheme.glow, radius: 10)
                            )
                    }

                    // HISTORY CHART
                    NeonCard(title: "Net Worth History") {

                        Text("Line chart uses dummy historical data for now.")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)

                        DummyLineChart()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FuturisticTheme.border, lineWidth: 1)
                                    .shadow(color: FuturisticTheme.glow, radius: 10)
                            )
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(FuturisticTheme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Asset List Screen

struct AssetListView: View {

    let title: String
    let assets: [Asset]

    var body: some View {

        List(assets) {

            asset in

            NavigationLink {

                AssetDetailView(asset: asset)

            } label: {

                HStack {

                    Text(asset.symbol)

                    Spacer()

                    Text("$\(asset.value, specifier: "%.2f")")
                        .bold()
                }
            }
        }
        .navigationTitle(title)
    }
}

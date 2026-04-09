import SwiftUI

// MARK: - Models

enum NetWorthCategory: String, CaseIterable, Identifiable, Codable {
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
    @EnvironmentObject private var assetStore: AssetStore

    // CATEGORY TOTALS CALCULATED FROM ASSETS
    private var categories: [CategorySummary] {
        NetWorthCategory.allCases.map { category in
            let total = assetStore.assets
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.value }

            return CategorySummary(category: category, totalValue: total)
        }
    }

    private var totalNetWorth: Double {
        assetStore.assets.reduce(0) { $0 + $1.value }
    }

    private func percent(for value: Double) -> Double {
        guard totalNetWorth > 0 else { return 0 }
        return (value / totalNetWorth) * 100
    }

    private func destinationView(for category: NetWorthCategory) -> AnyView {
        switch category {
        case .crypto:
            return AnyView(AssetListView(title: "Crypto", category: .crypto))

        case .stocks:
            return AnyView(AssetListView(title: "Stocks", category: .stocks))

        case .realEstate:
            return AnyView(AssetListView(title: "Real Estate", category: .realEstate))

        case .vehicles:
            return AnyView(AssetListView(title: "Vehicles", category: .vehicles))

        case .others:
            return AnyView(AssetListView(title: "Others", category: .others))
        }
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {
                    if let marketDataMessage = assetStore.marketDataMessage {
                        Text(marketDataMessage)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

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
                        DummyPieChart(data: categories)
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

                        Text("Net worth history will appear here as historical tracking is added.")
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await assetStore.refreshPrices(trigger: "manual refresh")
                        }
                    } label: {
                        if assetStore.isRefreshingPrices {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(assetStore.isRefreshingPrices)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddEditAssetView()
                    } label: {
                        Label("Add Asset", systemImage: "plus")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await assetStore.refreshPrices(trigger: "portfolio screen appeared")
            }
            .refreshable {
                await assetStore.refreshPrices(trigger: "pull to refresh")
            }
        }
    }
}

// MARK: - Asset List Screen

struct AssetListView: View {
    @EnvironmentObject private var assetStore: AssetStore

    let title: String
    let category: NetWorthCategory

    private var assets: [Asset] {
        assetStore.assets.filter { $0.category == category }
    }

    var body: some View {

        List(assets) {

            asset in

            NavigationLink {

                AssetDetailView(assetID: asset.id)

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
        .task {
            await assetStore.refreshPrices(trigger: "\(title) screen appeared")
        }
        .refreshable {
            await assetStore.refreshPrices(trigger: "\(title) pull to refresh")
        }
    }
}

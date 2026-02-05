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

// MARK: - Main View (Dashboard)

struct ContentView: View {

    // Dummy category totals
    private let categories: [CategorySummary] = [
        .init(category: .realEstate, totalValue: 170_000.00),
        .init(category: .crypto, totalValue: 94_479.00),
        .init(category: .stocks, totalValue: 35_916.65),
        .init(category: .vehicles, totalValue: 38_500.00),
        .init(category: .others, totalValue: 19_200.00)
    ]

    private var totalNetWorth: Double {
        categories.reduce(0) { $0 + $1.totalValue }
    }

    private func percent(for value: Double) -> Double {
        guard totalNetWorth > 0 else { return 0 }
        return (value / totalNetWorth) * 100.0
    }

    private func destinationView(for category: NetWorthCategory) -> AnyView {
        switch category {
        case .crypto: return AnyView(CryptoView())
        case .stocks: return AnyView(StocksView())
        case .realEstate: return AnyView(RealEstateView())
        case .vehicles: return AnyView(VehiclesView())
        case .others: return AnyView(OthersView())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // TOP HEADER
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

                    // 1️⃣ NET WORTH COMPOSITION TABLE
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

                    // 2️⃣ PIE CHART (DUMMY DATA)
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

                    // 3️⃣ NET WORTH HISTORY (DUMMY DATA)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(FuturisticTheme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
        }
    }
}

// MARK: - Placeholder Category Pages

struct CryptoView: View {
    var body: some View {
        categoryPlaceholder(title: "Crypto", subtitle: "Dummy holdings will be added next.")
    }
}

struct StocksView: View {
    var body: some View {
        categoryPlaceholder(title: "Stocks", subtitle: "Dummy holdings will be added next.")
    }
}

struct RealEstateView: View {
    var body: some View {
        categoryPlaceholder(title: "Real Estate", subtitle: "Dummy assets will be added next.")
    }
}

struct VehiclesView: View {
    var body: some View {
        categoryPlaceholder(title: "Vehicles", subtitle: "Dummy vehicles will be added next.")
    }
}

struct OthersView: View {
    var body: some View {
        categoryPlaceholder(title: "Others", subtitle: "Dummy items will be added next.")
    }
}

// MARK: - Shared Placeholder Layout

@ViewBuilder
private func categoryPlaceholder(title: String, subtitle: String) -> some View {
    VStack(spacing: 12) {
        Text(title)
            .font(.system(.largeTitle, design: .monospaced))
            .bold()
        Text(subtitle)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(FuturisticTheme.bg.ignoresSafeArea())
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
}

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

    // Dummy category totals (later: computed from holdings)
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

                    // 1) Composition Table
                    NeonCard(title: "Net Worth Composition") {
                        // Header
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

                        // Rows
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

                        // Total footer
                        HStack {
                            Text("TOTAL")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(FuturisticTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("$\(totalNetWorth, specifier: "%.2f")")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(.white)
                                .frame(width: 140, alignment: .trailing)

                            Text("100%")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(FuturisticTheme.good)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.top, 6)
                    }

                    // 2) Pie Chart placeholder
                    NeonCard(title: "Composition Pie") {
                        Text("Pie chart will go here (dummy for now).")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 220)
                            .overlay(
                                Text("PIE CHART")
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundStyle(FuturisticTheme.accent)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(FuturisticTheme.border, lineWidth: 1)
                                    .shadow(color: FuturisticTheme.glow, radius: 10)
                            )
                    }

                    // 3) Net Worth History placeholder
                    NeonCard(title: "Net Worth History") {
                        Text("Line chart will go here (dummy for now).")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 220)
                            .overlay(
                                Text("LINE CHART")
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundStyle(FuturisticTheme.accent)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(FuturisticTheme.border, lineWidth: 1)
                                    .shadow(color: FuturisticTheme.glow, radius: 10)
                            )
                    }
                }
                // ✅ SCROLL FIX: forces proper width and allows content to extend/scroll
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(FuturisticTheme.bg.ignoresSafeArea())
            .navigationTitle("BitBalance")
        }
    }
}

// MARK: - Placeholder Category Pages

struct CryptoView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Crypto")
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
            Text("Dummy holdings will be added next.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticTheme.bg.ignoresSafeArea())
        .navigationTitle("Crypto")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StocksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Stocks")
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
            Text("Dummy holdings will be added next.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticTheme.bg.ignoresSafeArea())
        .navigationTitle("Stocks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RealEstateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Real Estate")
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
            Text("Dummy assets will be added next.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticTheme.bg.ignoresSafeArea())
        .navigationTitle("Real Estate")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VehiclesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Vehicles")
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
            Text("Dummy vehicles will be added next.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticTheme.bg.ignoresSafeArea())
        .navigationTitle("Vehicles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OthersView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Others")
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
            Text("Dummy items will be added next.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticTheme.bg.ignoresSafeArea())
        .navigationTitle("Others")
        .navigationBarTitleDisplayMode(.inline)
    }
}


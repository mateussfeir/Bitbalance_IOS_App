import Foundation
import Combine

@MainActor
final class AssetStore: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var isRefreshingPrices = false
    @Published var marketDataMessage: String?

    private let storageKey = "asset_store_assets"
    private let priceService: PriceService
    private let defaults: UserDefaults

    init(
        priceService: PriceService = PriceService(),
        defaults: UserDefaults = .standard
    ) {
        self.priceService = priceService
        self.defaults = defaults
        self.assets = loadAssets()
    }

    func addAsset(symbol: String, quantity: Double, lastPrice: Double, category: NetWorthCategory) {
        let asset = Asset(
            symbol: normalizeDisplaySymbol(symbol, category: category),
            quantity: quantity,
            lastPrice: lastPrice,
            category: category
        )
        assets.append(asset)
        persistAssets()

        Task {
            await refreshPrices(for: [asset.id], trigger: "asset added")
        }
    }

    func updateAsset(id: UUID, symbol: String, quantity: Double, lastPrice: Double, category: NetWorthCategory) {
        guard let index = assets.firstIndex(where: { $0.id == id }) else {
            print("[AssetStore] Update skipped. Asset not found for id \(id)")
            marketDataMessage = "That asset could not be updated."
            return
        }

        assets[index].symbol = normalizeDisplaySymbol(symbol, category: category)
        assets[index].quantity = quantity
        assets[index].lastPrice = lastPrice
        assets[index].category = category
        persistAssets()

        Task {
            await refreshPrices(for: [id], trigger: "asset updated")
        }
    }

    func deleteAsset(id: UUID) {
        assets.removeAll { $0.id == id }
        persistAssets()
    }

    func asset(withID id: UUID) -> Asset? {
        assets.first { $0.id == id }
    }

    func refreshPrices(trigger: String) async {
        await refreshPrices(for: assets.map(\.id), trigger: trigger)
    }

    func refreshPrices(for assetIDs: [UUID], trigger: String) async {
        let targetAssets = assets.filter { assetIDs.contains($0.id) }
        let supportedAssets = targetAssets.filter { supportsLivePrices(for: $0.category) }

        guard !supportedAssets.isEmpty else {
            print("[AssetStore] No live-price assets to refresh for trigger: \(trigger)")
            marketDataMessage = nil
            return
        }

        isRefreshingPrices = true
        marketDataMessage = nil

        do {
            let outcome = try await priceService.fetchQuotes(for: supportedAssets)
            apply(quotes: outcome.quotes, trigger: trigger)
            marketDataMessage = outcome.notices.isEmpty ? nil : outcome.notices.joined(separator: " ")
        } catch {
            let logMessage = "Live price refresh failed during \(trigger): \(error.localizedDescription)"
            marketDataMessage = "Live prices are temporarily unavailable."
            print("[AssetStore] \(logMessage)")
        }

        isRefreshingPrices = false
    }

    func normalizeDisplaySymbol(_ symbol: String, category: NetWorthCategory) -> String {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard category == .crypto else { return trimmed }
        return trimmed.replacingOccurrences(of: "-USD", with: "")
    }

    private func supportsLivePrices(for category: NetWorthCategory) -> Bool {
        category == .stocks || category == .crypto
    }

    private func apply(quotes: [PriceQuote], trigger: String) {
        guard !quotes.isEmpty else {
            print("[AssetStore] No quotes returned for trigger: \(trigger)")
            return
        }

        var updatedSymbols: [String] = []

        for quote in quotes {
            let matchingIndexes = assets.indices.filter {
                assets[$0].symbol.uppercased() == quote.requestedSymbol.uppercased()
            }

            guard !matchingIndexes.isEmpty else {
                print("[AssetStore] Quote received for unknown asset \(quote.requestedSymbol)")
                continue
            }

            for index in matchingIndexes {
                assets[index].lastPrice = quote.price
            }
            updatedSymbols.append("\(quote.requestedSymbol)=\(quote.price)")
        }

        print("[AssetStore] Applied live prices for trigger \(trigger): \(updatedSymbols.joined(separator: ", "))")
        persistAssets()
    }

    private func loadAssets() -> [Asset] {
        guard let data = defaults.data(forKey: storageKey) else {
            let seeded = Self.seedAssets
            print("[AssetStore] No persisted assets found. Loading seed data.")
            return seeded
        }

        do {
            let decoded = try JSONDecoder().decode([Asset].self, from: data)
            print("[AssetStore] Loaded \(decoded.count) persisted assets.")
            return decoded
        } catch {
            print("[AssetStore] Failed to load persisted assets: \(error.localizedDescription)")
            return Self.seedAssets
        }
    }

    private func persistAssets() {
        do {
            let data = try JSONEncoder().encode(assets)
            defaults.set(data, forKey: storageKey)
            print("[AssetStore] Save success. Persisted \(assets.count) assets.")
        } catch {
            marketDataMessage = "Portfolio changes could not be saved."
            print("[AssetStore] Save failure: \(error.localizedDescription)")
        }
    }

    private static let seedAssets: [Asset] = [
        Asset(symbol: "BTC", quantity: 1.2, lastPrice: 60000, category: .crypto),
        Asset(symbol: "ETH", quantity: 5, lastPrice: 3000, category: .crypto),
        Asset(symbol: "AAPL", quantity: 50, lastPrice: 190, category: .stocks),
        Asset(symbol: "TSLA", quantity: 20, lastPrice: 250, category: .stocks),
        Asset(symbol: "PETR4.SA", quantity: 100, lastPrice: 35, category: .stocks),
        Asset(symbol: "Toronto Condo", quantity: 1, lastPrice: 170000, category: .realEstate),
        Asset(symbol: "Car", quantity: 1, lastPrice: 38500, category: .vehicles),
        Asset(symbol: "Cash Savings", quantity: 1, lastPrice: 19200, category: .others)
    ]
}

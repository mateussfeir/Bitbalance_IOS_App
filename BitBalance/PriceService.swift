import Foundation

struct PriceQuote: Sendable {
    let requestedSymbol: String
    let normalizedSymbol: String
    let providerName: String
    let price: Double
}

struct PriceFetchOutcome: Sendable {
    var quotes: [PriceQuote]
    var notices: [String]

    static let empty = PriceFetchOutcome(quotes: [], notices: [])
}

enum PriceServiceError: LocalizedError {
    case invalidURL(String)
    case invalidResponse(provider: String)
    case httpError(provider: String, statusCode: Int)
    case missingPrice(provider: String, symbol: String)
    case unsupportedCryptoSymbol(String)
    case stockProviderUnavailable
    case stockProviderMessage(String)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(urlString):
            return "Failed to build quote URL: \(urlString)"
        case let .invalidResponse(provider):
            return "\(provider) returned an invalid response."
        case let .httpError(provider, statusCode):
            return "\(provider) returned HTTP \(statusCode)."
        case let .missingPrice(provider, symbol):
            return "\(provider) did not include a price for \(symbol)."
        case let .unsupportedCryptoSymbol(symbol):
            return "Crypto symbol \(symbol) is not mapped to a supported live provider."
        case .stockProviderUnavailable:
            return "Stock quotes are unavailable until a stock API key is configured."
        case let .stockProviderMessage(message):
            return message
        }
    }
}

struct PriceService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let alphaVantageAPIKey: String?

    nonisolated init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        alphaVantageAPIKey: String? = PriceService.loadAlphaVantageAPIKey()
    ) {
        self.session = session
        self.decoder = decoder
        let trimmedAPIKey = alphaVantageAPIKey?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.alphaVantageAPIKey = trimmedAPIKey.isEmpty ? nil : trimmedAPIKey
    }

    func fetchQuotes(for assets: [Asset]) async throws -> PriceFetchOutcome {
        let normalizedAssets = assets.map(normalizeRequest(for:))
        let cryptoAssets = normalizedAssets.filter { $0.provider == .coinGecko }
        let stockAssets = normalizedAssets.filter { $0.provider == .alphaVantage }
        var quotes: [PriceQuote] = []
        var notices: [String] = []

        do {
            let cryptoOutcome = try await fetchCryptoQuotes(for: cryptoAssets)
            quotes.append(contentsOf: cryptoOutcome.quotes)
            notices.append(contentsOf: cryptoOutcome.notices)
        } catch {
            print("[PriceService] Provider=CoinGecko fetch failed: \(error.localizedDescription)")
            notices.append("Crypto prices are temporarily unavailable. Saved values are still shown.")
        }

        do {
            let stockOutcome = try await fetchStockQuotes(for: stockAssets)
            quotes.append(contentsOf: stockOutcome.quotes)
            notices.append(contentsOf: stockOutcome.notices)
        } catch {
            print("[PriceService] Provider=AlphaVantage fetch failed: \(error.localizedDescription)")
            notices.append("Stock prices are temporarily unavailable. Saved values are still shown.")
        }

        return PriceFetchOutcome(quotes: quotes, notices: notices)
    }

    private func fetchCryptoQuotes(for assets: [NormalizedAssetRequest]) async throws -> PriceFetchOutcome {
        guard !assets.isEmpty else { return .empty }

        let providerName = PriceProvider.coinGecko.rawValue
        var uniqueIDs: [String] = []
        for asset in assets where !uniqueIDs.contains(asset.providerSymbol) {
            uniqueIDs.append(asset.providerSymbol)
        }

        let ids = uniqueIDs.joined(separator: ",")
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd"

        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            print("[PriceService] Provider=\(providerName) invalid URL: \(urlString)")
            throw PriceServiceError.invalidURL(urlString)
        }

        for asset in assets {
            print("[PriceService] Provider=\(providerName) requestedSymbol=\(asset.requestedSymbol) normalizedSymbol=\(asset.providerSymbol)")
        }
        print("[PriceService] Provider=\(providerName) Request URL: \(url.absoluteString)")

        let (data, response) = try await session.data(from: url)
        let httpResponse = try validateHTTPResponse(response, data: data, providerName: providerName)
        print("[PriceService] Provider=\(providerName) HTTP status: \(httpResponse.statusCode)")

        let payload: [String: CoinGeckoPrice]
        do {
            payload = try decoder.decode([String: CoinGeckoPrice].self, from: data)
        } catch {
            print("[PriceService] Provider=\(providerName) decode failure snippet: \(responseSnippet(from: data))")
            throw error
        }

        let quotes = try assets.map { asset in
            guard let coin = payload[asset.providerSymbol],
                  let price = coin.usd else {
                throw PriceServiceError.missingPrice(provider: providerName, symbol: asset.providerSymbol)
            }

            print("[PriceService] Provider=\(providerName) decoded price requested=\(asset.requestedSymbol) normalized=\(asset.providerSymbol) value=\(price)")
            return PriceQuote(
                requestedSymbol: asset.requestedSymbol,
                normalizedSymbol: asset.providerSymbol,
                providerName: providerName,
                price: price
            )
        }

        return PriceFetchOutcome(quotes: quotes, notices: [])
    }

    private func fetchStockQuotes(for assets: [NormalizedAssetRequest]) async throws -> PriceFetchOutcome {
        guard !assets.isEmpty else { return .empty }

        guard let alphaVantageAPIKey else {
            for asset in assets {
                print("[PriceService] Provider=AlphaVantage stock quote skipped for \(asset.requestedSymbol). Missing API key.")
            }
            return PriceFetchOutcome(
                quotes: [],
                notices: ["Stock live prices are unavailable until an Alpha Vantage API key is configured. Saved stock values are still shown."]
            )
        }

        var quotes: [PriceQuote] = []
        var notices: [String] = []

        try await withThrowingTaskGroup(of: PriceQuote.self) { group in
            for asset in assets {
                group.addTask {
                    try await fetchAlphaVantageQuote(for: asset, apiKey: alphaVantageAPIKey)
                }
            }

            do {
                for try await quote in group {
                    quotes.append(quote)
                }
            } catch let error as PriceServiceError {
                if case let .stockProviderMessage(message) = error {
                    notices.append(message)
                    group.cancelAll()
                } else {
                    group.cancelAll()
                    throw error
                }
            }
        }

        return PriceFetchOutcome(quotes: quotes, notices: notices)
    }

    private func fetchAlphaVantageQuote(
        for asset: NormalizedAssetRequest,
        apiKey: String
    ) async throws -> PriceQuote {
        let providerName = PriceProvider.alphaVantage.rawValue
        let urlString = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(asset.providerSymbol)&apikey=\(apiKey)"

        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            print("[PriceService] Provider=\(providerName) invalid URL for symbol \(asset.providerSymbol)")
            throw PriceServiceError.invalidURL(urlString)
        }

        let redactedURL = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(asset.providerSymbol)&apikey=<redacted>"
        print("[PriceService] Provider=\(providerName) requestedSymbol=\(asset.requestedSymbol) normalizedSymbol=\(asset.providerSymbol)")
        print("[PriceService] Provider=\(providerName) Request URL: \(redactedURL)")

        let (data, response) = try await session.data(from: url)
        let httpResponse = try validateHTTPResponse(response, data: data, providerName: providerName)
        print("[PriceService] Provider=\(providerName) HTTP status: \(httpResponse.statusCode)")

        let payload: AlphaVantageQuoteResponse
        do {
            payload = try decoder.decode(AlphaVantageQuoteResponse.self, from: data)
        } catch {
            print("[PriceService] Provider=\(providerName) decode failure snippet: \(responseSnippet(from: data))")
            throw error
        }

        if let note = nonEmptyString(payload.note) {
            print("[PriceService] Provider=\(providerName) response note: \(note)")
            throw PriceServiceError.stockProviderMessage("Stock prices are temporarily rate-limited. Saved values are still shown.")
        }

        if let information = nonEmptyString(payload.information) {
            print("[PriceService] Provider=\(providerName) response info: \(information)")
            throw PriceServiceError.stockProviderMessage("Stock live prices require a valid Alpha Vantage API key. Saved values are still shown.")
        }

        guard let rawPrice = payload.globalQuote.price,
              let price = Double(rawPrice) else {
            print("[PriceService] Provider=\(providerName) missing price snippet: \(responseSnippet(from: data))")
            throw PriceServiceError.missingPrice(provider: providerName, symbol: asset.providerSymbol)
        }

        print("[PriceService] Provider=\(providerName) decoded price requested=\(asset.requestedSymbol) normalized=\(asset.providerSymbol) value=\(price)")
        return PriceQuote(
            requestedSymbol: asset.requestedSymbol,
            normalizedSymbol: asset.providerSymbol,
            providerName: providerName,
            price: price
        )
    }

    private func normalizeRequest(for asset: Asset) -> NormalizedAssetRequest {
        let requestedSymbol = asset.symbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        switch asset.category {
        case .crypto:
            let providerSymbol = Self.coinGeckoIDBySymbol[requestedSymbol] ?? requestedSymbol.lowercased()
            return NormalizedAssetRequest(
                requestedSymbol: requestedSymbol,
                providerSymbol: providerSymbol,
                provider: .coinGecko
            )
        case .stocks:
            let providerSymbol = normalizeStockSymbolForAlphaVantage(requestedSymbol)
            return NormalizedAssetRequest(
                requestedSymbol: requestedSymbol,
                providerSymbol: providerSymbol,
                provider: .alphaVantage
            )
        case .realEstate, .vehicles, .others:
            return NormalizedAssetRequest(
                requestedSymbol: requestedSymbol,
                providerSymbol: requestedSymbol,
                provider: .unsupported
            )
        }
    }

    private func normalizeStockSymbolForAlphaVantage(_ symbol: String) -> String {
        if symbol.hasSuffix(".SA") {
            return symbol.replacingOccurrences(of: ".SA", with: ".SAO")
        }
        return symbol
    }

    private func validateHTTPResponse(
        _ response: URLResponse,
        data: Data,
        providerName: String
    ) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[PriceService] Provider=\(providerName) invalid response object.")
            throw PriceServiceError.invalidResponse(provider: providerName)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("[PriceService] Provider=\(providerName) HTTP status: \(httpResponse.statusCode)")
            print("[PriceService] Provider=\(providerName) failure snippet: \(responseSnippet(from: data))")
            throw PriceServiceError.httpError(provider: providerName, statusCode: httpResponse.statusCode)
        }

        return httpResponse
    }

    private func responseSnippet(from data: Data) -> String {
        let text = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        return String(text.prefix(240))
    }

    private func nonEmptyString(_ value: String?) -> String? {
        guard let value else { return nil }
        return value.isEmpty ? nil : value
    }

    private static func loadAlphaVantageAPIKey() -> String? {
        if let bundledSecretsURL = Bundle.main.url(forResource: "LocalSecrets", withExtension: "plist"),
           let bundledSecrets = NSDictionary(contentsOf: bundledSecretsURL) as? [String: Any],
           let bundledKey = bundledSecrets["ALPHA_VANTAGE_API_KEY"] as? String,
           !bundledKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bundledKey
        }

        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "ALPHA_VANTAGE_API_KEY") as? String,
           !infoKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return infoKey
        }

        return nil
    }

    private static let coinGeckoIDBySymbol: [String: String] = [
        "ADA": "cardano",
        "ARB": "arbitrum",
        "AVAX": "avalanche-2",
        "BNB": "binancecoin",
        "BTC": "bitcoin",
        "DOGE": "dogecoin",
        "DOT": "polkadot",
        "ETH": "ethereum",
        "LINK": "chainlink",
        "LTC": "litecoin",
        "MATIC": "matic-network",
        "SOL": "solana",
        "TON": "the-open-network",
        "TRX": "tron",
        "UNI": "uniswap",
        "USDC": "usd-coin",
        "USDT": "tether",
        "XRP": "ripple"
    ]
}

private enum PriceProvider: String {
    case coinGecko = "CoinGecko"
    case alphaVantage = "AlphaVantage"
    case unsupported = "Unsupported"
}

private struct NormalizedAssetRequest {
    let requestedSymbol: String
    let providerSymbol: String
    let provider: PriceProvider
}

private struct CoinGeckoPrice: Decodable {
    let usd: Double?
}

private struct AlphaVantageQuoteResponse: Decodable {
    let globalQuote: AlphaVantageGlobalQuote
    let note: String?
    let information: String?

    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
        case note = "Note"
        case information = "Information"
    }
}

private struct AlphaVantageGlobalQuote: Decodable {
    let symbol: String?
    let price: String?

    enum CodingKeys: String, CodingKey {
        case symbol = "01. symbol"
        case price = "05. price"
    }
}

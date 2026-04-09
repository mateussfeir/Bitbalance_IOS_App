import Foundation

struct Asset: Identifiable, Codable {
    var id: UUID
    var symbol: String
    var quantity: Double
    var lastPrice: Double
    var category: NetWorthCategory

    init(
        id: UUID = UUID(),
        symbol: String,
        quantity: Double,
        lastPrice: Double,
        category: NetWorthCategory
    ) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.lastPrice = lastPrice
        self.category = category
    }

    var value: Double {
        quantity * lastPrice
    }
}

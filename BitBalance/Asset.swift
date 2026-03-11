import Foundation

struct Asset: Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Double
    let lastPrice: Double
    let category: NetWorthCategory

    var value: Double {
        quantity * lastPrice
    }
}

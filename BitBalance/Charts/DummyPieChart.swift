import SwiftUI
import Charts

struct DummyPieChart: View {

    let data: [(category: String, value: Double)] = [
        ("Real Estate", 47.47),
        ("Crypto", 26.38),
        ("Stocks", 10.03),
        ("Vehicles", 10.75),
        ("Others", 5.36)
    ]

    var body: some View {
        Chart(data, id: \.category) { item in
            SectorMark(
                angle: .value("Percentage", item.value)
            )
            .foregroundStyle(by: .value("Category", item.category))
        }
        .chartLegend(.hidden)
        .frame(height: 220)
    }
}

#Preview {
    DummyPieChart()
}

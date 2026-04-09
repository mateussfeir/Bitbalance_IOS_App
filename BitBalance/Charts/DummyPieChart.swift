import SwiftUI
import Charts

struct DummyPieChart: View {
    let data: [CategorySummary]

    private var populatedData: [CategorySummary] {
        data.filter { $0.totalValue > 0 }
    }

    var body: some View {
        Group {
            if populatedData.isEmpty {
                ContentUnavailableView("No Asset Data", systemImage: "chart.pie")
                    .frame(height: 220)
            } else {
                Chart(populatedData) { item in
                    SectorMark(
                        angle: .value("Value", item.totalValue)
                    )
                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 220)
            }
        }
    }
}

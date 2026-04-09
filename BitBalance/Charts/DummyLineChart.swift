import SwiftUI
import Charts

struct NetWorthPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct DummyLineChart: View {

    let data: [NetWorthPoint] = [
        .init(date: daysAgo(30), value: 310_000),
        .init(date: daysAgo(25), value: 318_500),
        .init(date: daysAgo(20), value: 305_200),
        .init(date: daysAgo(15), value: 299_000),
        .init(date: daysAgo(10), value: 317_800),
        .init(date: daysAgo(5),  value: 350_400),
        .init(date: daysAgo(0),  value: 370_095)
    ]

    private var minValue: Double {
        data.map { $0.value }.min() ?? 0
    }

    private var maxValue: Double {
        data.map { $0.value }.max() ?? 0
    }

    private var paddedRange: ClosedRange<Double> {
        let padding = (maxValue - minValue) * 0.05
        return (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Net Worth", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(FuturisticTheme.good)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Net Worth", point.value)
            )
            .foregroundStyle(FuturisticTheme.good)
        }
        .chartYScale(domain: paddedRange)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
    }
}

private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date())!
}

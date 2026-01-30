import SwiftUI

struct NeonCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title.uppercased())
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(FuturisticTheme.accent)
            }

            content
        }
        .padding(16)
        .background(FuturisticTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FuturisticTheme.border, lineWidth: 1)
                .shadow(color: FuturisticTheme.glow, radius: 10)
        )
    }
}

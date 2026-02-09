import SwiftUI

struct InvoiceStyleSelectionView: View {

    let style: InvoiceStyle

    var body: some View {
        HStack(spacing: 12) {
            Text(style.displayName)
                .font(.poppins(size: 16, weight: .regular))
                .foregroundStyle(.textPrimary)

            InvoiceStyleColorsView(theme: style.theme, isSelected: false)
                .frame(width: 24, height: 24)
                .shadow(color: .shadow, radius: 4)

            Spacer()

            Icon(systemName: "chevron.forward")
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.border, lineWidth: 1)
        }
    }
}

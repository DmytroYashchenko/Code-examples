import SwiftUI

struct InvoicePartySelectionView: View {

    let title: LocalizedStringKey
    let name: String?

    var body: some View {
        HStack(spacing: 12) {
            if let name {
                Text(name)
                    .font(.poppins(size: 16, weight: .regular))
                    .foregroundStyle(.textPrimary)

                Spacer()

                Icon(systemName: "chevron.forward")
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.textPrimary)
            } else {
                Spacer()

                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.textProminent)

                Text(title)
                    .font(.poppins(size: 14, weight: .semiBold))
                    .foregroundStyle(.textProminent)

                Spacer()
            }
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

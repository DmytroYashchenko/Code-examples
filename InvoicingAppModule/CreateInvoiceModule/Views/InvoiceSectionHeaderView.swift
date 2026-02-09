import SwiftUI

struct InvoiceSectionHeaderView: View {

    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.poppins(size: 12, weight: .regular))
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

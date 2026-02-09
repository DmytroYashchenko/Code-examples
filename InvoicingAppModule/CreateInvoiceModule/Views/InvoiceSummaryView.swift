import SwiftUI

struct InvoiceSummaryView: View {

    let input: InvoiceInput
    let currency: Currency
    let discountTapHandler: () -> Void
    let taxTapHandler: () -> Void
    let currencyTapHandler: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if input.workItems.isEmpty {
                TotalView(
                    currency: currency,
                    totalAmount: 0,
                    currencyTapHandler: currencyTapHandler
                )
            } else {
                let totals = input.totals

                SubtotalView(
                    title: String(localized: "Subtotal"),
                    amount: totals.subtotal,
                    tapHandler: nil
                )
                divider

                SubtotalView(
                    title: totals.discountTitle,
                    amount: totals.discountValue,
                    tapHandler: {
                        discountTapHandler()
                    }
                )
                divider

                SubtotalView(
                    title: totals.taxTitle,
                    amount: totals.taxValue,
                    tapHandler: {
                        taxTapHandler()
                    }

                )
                divider

                TotalView(
                    currency: currency,
                    totalAmount: totals.total,
                    currencyTapHandler: currencyTapHandler
                )
            }
        }
        .padding(12)
        .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.border, lineWidth: 1)
        }
    }

    var divider: some View {
        Divider().background(.textSecondary)
    }
}

// MARK: - TotalView

private struct TotalView: View {

    let currency: Currency
    let totalAmount: Double
    let currencyTapHandler: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Total")
                .font(.poppins(size: 16, weight: .semiBold))
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                currencyTapHandler()
            } label: {
                HStack(spacing: 4) {
                    Text(currency.code)
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundStyle(.textPrimary)

                    Icon(systemName: "chevron.down")
                        .scaledToFit()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(.textPrimary)
                }
                .padding(4)
                .background(.backgroundSecondary, in: .rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.border, lineWidth: 1)
                }
            }

            Text(totalAmount.formattedPrice(currency: currency))
                .font(.poppins(size: 16, weight: .semiBold))
                .foregroundStyle(.textProminent)
        }
    }
}

// MARK: - SubtotalView

struct SubtotalView: View {

    let title: String
    let amount: Double
    var tapHandler: (() -> Void)?

    var body: some View {
        if let tapHandler {
            Button {
                tapHandler()
            } label: {
                content
            }
        } else {
            content
        }
    }

    var content: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.poppins(size: 16, weight: .regular))
                .foregroundStyle(.textPrimary)

            Spacer()

            Text(amount.formattedPrice())
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(.textPrimary)

            if tapHandler != nil {
                Icon(systemName: "chevron.forward")
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.textPrimary)
            }
        }
    }
}

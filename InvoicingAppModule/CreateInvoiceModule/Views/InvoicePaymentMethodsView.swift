import SwiftUI

// MARK: - InvoicePaymentMethodsView

struct InvoicePaymentMethodsView: View {

    let paymentMethods: [AnyPaymentMethod]
    let tapHandler: (_ paymentMethod: any PaymentMethod) -> Void
    let removeHandler: (_ paymentMethod: any PaymentMethod) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(paymentMethods) { paymentMethod in
                let isLastItem = paymentMethod == paymentMethods.last
                Button {
                    tapHandler(paymentMethod)
                } label: {
                    ItemView(
                        paymentMethod: paymentMethod,
                        removeHandler: removeHandler
                    )
                }
                if !isLastItem {
                    Divider()
                        .background(.textSecondary)
                }
            }
        }
        .padding(12)
        .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.border, lineWidth: 1)
        }
    }
}

// MARK: - Item view

private struct ItemView: View {

    let paymentMethod: AnyPaymentMethod
    let removeHandler: (_ paymentMethod: any PaymentMethod) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
               removeHandler(paymentMethod)
            } label: {
                Icon(systemName: "trash")
                    .scaledToFit()
                    .frame(height: 16)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.icon)

            HStack(spacing: 8) {
                Text(paymentMethod.title)
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundStyle(.textPrimary)

                Image(paymentMethod.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Icon(systemName: "chevron.forward")
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.textPrimary)
        }
    }
}

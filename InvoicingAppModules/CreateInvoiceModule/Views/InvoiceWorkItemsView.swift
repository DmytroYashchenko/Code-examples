import SwiftUI

// MARK: - InvoiceWorkItemsView

struct InvoiceWorkItemsView: View {

    let workItems: [WorkItem]
    let tapHandler: (_ workItem: WorkItem) -> Void
    let removeHandler: (_ workItem: WorkItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(workItems) { workItem in
                let isLastItem = workItem == workItems.last
                Button {
                    tapHandler(workItem)
                } label: {
                    ItemView(
                        workItem: workItem,
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

    let workItem: WorkItem
    let removeHandler: (_ workItem: WorkItem) -> Void

    var description: String {
        var description = "\(workItem.quantity)\(workItem.unitType?.shortTitle ?? "")"
        + " x \(workItem.price.formattedPrice())"
        if let discount = workItem.discount {
            let discountTitle = String(localized: "Discount")
            switch discount {
            case .percentage(let amount):
                description += " - \(amount)% \(discountTitle)"
            case .fixed(let amount):
                description += " - \(amount.formattedPrice()) \(discountTitle)"
            }
        }
        return description
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
               removeHandler(workItem)
            } label: {
                Icon(systemName: "trash")
                    .scaledToFit()
                    .frame(height: 16)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.icon)

            VStack(alignment: .leading, spacing: 8) {
                Text(workItem.name)
                    .font(.poppins(size: 16, weight: .medium))
                    .foregroundStyle(.textPrimary)

                Text(description)
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(workItem.amount.formattedPrice())
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(.textPrimary)

            Icon(systemName: "chevron.forward")
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.textPrimary)
        }
    }
}

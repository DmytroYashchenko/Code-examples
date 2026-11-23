import SwiftUI

struct InvoiceDetailsView: View {

    @ObservedObject var viewModel: InvoiceDetailsViewModel

    @State private var isDeleteConfirmationShown = false

    var body: some View {
        NavigationView {
            VStack(spacing: .zero) {
                headerView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Rectangle()
                    .fill(.border)
                    .frame(height: 1)

                ScrollView {
                    VStack(spacing: .zero) {
                        mainInfoView
                            .padding(.bottom, 16)

                        paymentSwitcherView
                            .padding(.bottom, 16)

                        secondaryInfoView
                            .padding(.bottom, 16)

                        notesView
                    }
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.invoice.isPaid)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: .zero) {
                    LinearGradient(
                        colors: [.clear, .backgroundPrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 14)

                    actionsView
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 16)
                        .background(.backgroundPrimary)

                    Button("Send Invoice") {
                        viewModel.shareTapped()
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .background(.backgroundPrimary)
                }
            }
            .background(.backgroundPrimary)
        }
    }
}

// MARK: - Subviews

private extension InvoiceDetailsView {

    var headerView: some View {
        Text("Details")
            .font(.poppins(size: 22, weight: .semiBold))
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    viewModel.backTapped()
                } label: {
                    Icon(systemName: "chevron.backward")
                        .scaledToFit()
                        .frame(height: 18)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.icon)
            }
            .overlay(alignment: .trailing) {
                HStack(spacing: 24) {
                    Button {
                        viewModel.editTapped()
                    } label: {
                        Icon(systemName: "square.and.pencil")
                            .scaledToFit()
                            .frame(height: 18)
                            .foregroundStyle(.textPrimary)
                    }
                    .buttonStyle(.icon)

                    Button {
                        isDeleteConfirmationShown = true
                    } label: {
                        Icon(systemName: "trash")
                            .scaledToFit()
                            .frame(height: 18)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.icon)
                    .alert(
                        "Delete invoice?",
                        isPresented: $isDeleteConfirmationShown
                    ) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteInvoiceTapped()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this invoice? This action cannot be undone")
                    }
                }
            }
    }

    @ViewBuilder
    var previewButton: some View {
        let width: CGFloat = 120
        let lineView = Capsule()
            .foregroundStyle(.textSecondary)
            .frame(height: 1)

        Button {
            viewModel.previewTapped()
        } label: {
            VStack(alignment: .leading, spacing: .zero) {
                HStack {
                    VStack(spacing: 4) {
                        Text("PREVIEW")
                            .font(.poppins(size: 8, weight: .regular))
                            .foregroundStyle(.textPrimary)
                        ForEach(0...3, id: \.self) { _ in
                            lineView.frame(width: width * 0.3)
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Icon(.icSignatureExample)
                            .scaledToFit()
                            .frame(height: 18)
                            .foregroundStyle(.textPrimary)

                        lineView.frame(width: width * 0.3)
                        lineView.frame(width: width * 0.3)
                    }
                }

                .padding(.bottom, 8)

                VStack(spacing: 4) {
                    ForEach(0...2, id: \.self) { _ in
                        HStack(spacing: 8) {
                            ForEach(0...1, id: \.self) { _ in
                                lineView
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                VStack(spacing: 4) {
                    ForEach(0...3, id: \.self) { _ in
                        lineView.frame(width: width)
                    }
                }
            }
            .frame(width: width)
            .padding(8)
            .padding(.bottom, 16)
            .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
            .shadow(color: .shadow, radius: 4)
            .overlay {
                Icon(.previewDocument)
                    .scaledToFit()
                    .frame(height: 28)
                    .foregroundStyle(.textPrimary)
                    .padding(12)
                    .background {
                        Circle()
                            .foregroundStyle(.backgroundSecondary)
                            .blur(radius: 4)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.border, lineWidth: 1)
            }
            .offset(x: 0, y: 16)
        }
        .buttonStyle(.icon)
    }

    @ViewBuilder
    var mainInfoView: some View {
        let invoice = viewModel.invoice
        VStack(spacing: .zero) {
            previewButton

            VStack(spacing: 16) {
                if let recipientName = invoice.recipient?.name {
                    Text(recipientName)
                        .font(.poppins(size: 20, weight: .semiBold))
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                }
                Text(invoice.totals.total.formattedPrice(currency: invoice.currency))
                    .font(.poppins(size: 27, weight: .semiBold))
                    .foregroundStyle(.textPrimary)

                if invoice.isPaid {
                    Text("Paid")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundStyle(.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                        .frame(height: 24)
                        .background(.green700, in: .capsule)
                } else {
                    Text(invoice.paymentTermsData.text)
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundStyle(invoice.paymentTermsData.color)
                        .frame(height: 24)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
            .overlay {
                let strokeColor = invoice.isPaid
                ? .green700
                : invoice.paymentTermsData.color
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, style: .init(lineWidth: 1, dash: [5, 5]))
            }
            .animation(.default, value: invoice.isPaid)
        }
    }

    @ViewBuilder
    var secondaryInfoView: some View {
        let invoice = viewModel.invoice
        let divider = Divider().background(.textSecondary)

        VStack(spacing: 12) {
            let raws = SecondaryInfoRawView.makeAvailableRaws(with: invoice)
            ForEach(raws) { raw in
                let isLast = raws.last == raw

                raw
                if !isLast {
                    divider
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

    @ViewBuilder
    var paymentSwitcherView: some View {
        HStack(spacing: 16) {
            Text("💸 Is invoice paid?")
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(.textPrimary)

            Spacer()

            Toggle("", isOn: .init(
                get: {
                    viewModel.invoice.isPaid
                }, set: {
                    viewModel.switchPaidStatusTapped($0)
                }
            ))
            .tint(.linkedIn)
            .labelsHidden()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    var notesView: some View {
        if let notes = viewModel.invoice.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundStyle(.textPrimary)

                Text(notes)
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.border, lineWidth: 1)
            }
        }
    }

    var actionsView: some View {
        HStack(spacing: 16) {
            ActionView(
                image: .init(systemName: "square.and.arrow.up"),
                title: "Share",
                isProcessing: viewModel.isShareProcessing
            ) {
                viewModel.shareTapped()
            }
            .frame(width: 88)

            ActionView(
                image: .init(systemName: "printer"),
                title: "Print",
                isProcessing: viewModel.isPrintProcessing
            ) {
                viewModel.printTapped()
            }
            .frame(width: 88)

            ActionView(
                image: .init(systemName: "doc.on.doc"),
                title: "Duplicate",
                isProcessing: false
            ) {
                viewModel.duplicateTapped()
            }
            .frame(width: 88)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SecondaryInfoRawView

private struct SecondaryInfoRawView: View, Identifiable, Equatable {

    let title: LocalizedStringKey
    let value: String

    var id: String {
        "\(title),\(value)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(.textPrimary)

            Text(value)
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    static func makeAvailableRaws(with invoice: Invoice) -> [SecondaryInfoRawView] {
        var result = [SecondaryInfoRawView]()
        if let number = invoice.number, !number.isEmpty {
            result.append(SecondaryInfoRawView(
                title: "Number #",
                value: number
            ))
        }

        result.append(SecondaryInfoRawView(
            title: "Issued date",
            value: invoice.issuedDate.formatted(.dateTime.day().month(.abbreviated).year())
        ))

        result.append(SecondaryInfoRawView(
            title: "Due date",
            value: invoice.dueDate.dateTitle(from: invoice.issuedDate)
        ))

        if let paidDate = invoice.paidDate {
            result.append(SecondaryInfoRawView(
                title: "Paid date",
                value: paidDate.formatted(.dateTime.day().month(.abbreviated).year())
            ))
        }

        if let issuerName = invoice.issuer?.name {
            result.append(SecondaryInfoRawView(
                title: "Issuer",
                value: issuerName
            ))
        }

        if let recipientName = invoice.recipient?.name {
            result.append(SecondaryInfoRawView(
                title: "Recipient",
                value: recipientName
            ))
        }

        return result
    }
}

// MARK: - SecondaryInfoRawView

private struct ActionView: View {

    let image: Image
    let title: LocalizedStringKey
    let isProcessing: Bool
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                image
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.textPrimary)
                    .frame(width: 12, height: 12)
                    .opacity(isProcessing ? 0 : 1)

                Text(title)
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundStyle(.textPrimary)
                    .opacity(isProcessing ? 0 : 1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background {
                Capsule()
                    .fill(.backgroundSecondary)
                    .shadow(color: .shadow, radius: 4)
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .linkedIn))
                }
            }
        }
        .buttonStyle(.icon)
    }
}

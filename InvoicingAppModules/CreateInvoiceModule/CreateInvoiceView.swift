import SwiftUIExt

struct CreateInvoiceView: View {

    @ObservedObject var viewModel: CreateInvoiceViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: .zero) {
                headerView
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: .zero) {
                        Text("New Invoice")
                            .font(.poppins(size: 27, weight: .semiBold))
                            .foregroundStyle(.textPrimary)
                            .padding(.bottom, 16)

                        InvoiceDatesSelectionView(
                            issuedDate: $viewModel.builder.issuedDate,
                            dueDate: $viewModel.builder.dueDate,
                            number: $viewModel.builder.invoiceNumber
                        )
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Issuer")
                            .padding(.bottom, 8)

                        Button {
                            viewModel.issuerTapped()
                        } label: {
                            InvoicePartySelectionView(
                                title: "Add issuer  📤",
                                name: viewModel.builder.issuer?.name
                            )
                        }
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Client")
                            .padding(.bottom, 8)

                        Button {
                            viewModel.clientTapped()
                        } label: {
                            InvoicePartySelectionView(
                                title: "Add client  📥",
                                name: viewModel.builder.recipient?.name
                            )
                        }
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Items")
                            .padding(.bottom, 8)

                        if !viewModel.builder.workItems.isEmpty {
                            InvoiceWorkItemsView(
                                workItems: viewModel.builder.workItems,
                                tapHandler: {
                                    viewModel.itemTapped($0)
                                },
                                removeHandler: {
                                    viewModel.removeWorkItem($0)
                                }
                            )
                            .padding(.bottom, 8)
                        }

                        Button {
                            viewModel.addItemTapped()
                        } label: {
                            InvoicePartySelectionView(
                                title: "Add item  📦",
                                name: nil
                            )
                        }
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Summary")
                            .padding(.bottom, 8)

                        InvoiceSummaryView(
                            input: viewModel.builder,
                            currency: viewModel.builder.currency,
                            discountTapHandler: {
                                viewModel.discountTapped()
                            },
                            taxTapHandler: {
                                viewModel.taxTapped()
                            },
                            currencyTapHandler: {
                                viewModel.currencyTapped()
                            }
                        )
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Payment Options")
                            .padding(.bottom, 8)

                        if !viewModel.builder.paymentMethods.isEmpty {
                            InvoicePaymentMethodsView(
                                paymentMethods: viewModel.builder.invoicePaymentMethods,
                                tapHandler: {
                                    viewModel.paymentMethodTapped($0)
                                },
                                removeHandler: {
                                    viewModel.removePaymentMethod($0)
                                }
                            )
                            .padding(.bottom, 8)
                        }

                        Button {
                            viewModel.addPaymentMethodTapped()
                        } label: {
                            InvoicePartySelectionView(
                                title: "Add payment option  💵",
                                name: nil
                            )
                        }
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Style")
                            .padding(.bottom, 8)

                        Button {
                            viewModel.styleTapped()
                        } label: {
                            InvoiceStyleSelectionView(style: viewModel.builder.style)
                        }
                        .padding(.bottom, 16)

                        InvoiceSectionHeaderView(title: "Notes")
                            .padding(.bottom, 8)

                        InvoiceNotesView(text: $viewModel.builder.invoiceNotes)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 16)
            .toast(
                isPresented: $viewModel.itemAlreadyAddedToastIsShown,
                location: .bottom,
                toast: {
                    ToastView(title: "Work item is already added")
                }
            )
            .toast(
                isPresented: $viewModel.paymentMethodAlreadyAddedToastIsShown,
                location: .bottom,
                toast: {
                    ToastView(title: "Payment option is already added")
                }
            )
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: .zero) {
                    LinearGradient(
                        colors: [.clear, .backgroundPrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 14)
                    Button("Create Invoice") {
                        viewModel.createInvoiceTapped()
                    }
                    .buttonStyle(.primary)
                    .padding(.bottom, 24)
                    .padding(.top, 6)
                    .padding(.horizontal, 16)
                    .background(.backgroundPrimary)
                }
            }
            .background(.backgroundPrimary)
            .hideKeyboardToolbar()
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
}

// MARK: - Subviews

private extension CreateInvoiceView {

    var headerView: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.cancelTapped()
            } label: {
                Text("Cancel")
                    .font(.poppins(size: 16, weight: .regular))
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            Button {
                viewModel.previewTapped()
            } label: {
                Text("Preview")
                    .font(.poppins(size: 16, weight: .regular))
                    .foregroundStyle(.textPrimary)
            }
        }
    }
}

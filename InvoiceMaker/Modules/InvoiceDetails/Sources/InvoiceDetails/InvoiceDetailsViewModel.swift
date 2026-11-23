import CombineExt
import Core
import Depin

@MainActor
class InvoiceDetailsViewModel: ObservableObject {

    // MARK: - Injected properties

    @Injected private var appStorage: AppStorage
    @Injected private var databaseManager: DatabaseManager
    @Injected private var shareService: ShareInvoiceService
    @Injected private var printService: PrintInvoiceService

    private let router: InvoiceDetailsRouter

    // MARK: - Public properties

    @Published var invoice: Invoice
    @Published var isShareProcessing = false
    @Published var isPrintProcessing = false

    // MARK: - Private properties

    private var bag = CancelBag()

    init(
        router: InvoiceDetailsRouter,
        invoice: Invoice
    ) {
        self.router = router
        self.invoice = invoice

        InvoiceDetailsEvent.screenShown
            .send()

        bind()
    }

    private func bind() {
        databaseManager.$invoices
            .dropFirst()
            .map { $0.map(Invoice.init) }
            .sink { [weak self] in
                guard
                    let self,
                    let updatedInvoice = $0.first(where: { $0.id == self.invoice.id })
                else {
                    return
                }
                invoice = updatedInvoice
            }
            .store(in: &bag)
    }

    private func shareInvoice() {
        isShareProcessing = true
        shareService.share(invoice) { [weak self] in
            self?.isShareProcessing = false
        }
    }

    private func printInvoice() {
        isPrintProcessing = true
        printService.print(invoice) { [weak self] in
            self?.isPrintProcessing = false
        }
    }

    private func duplicateInvoice() {
        databaseManager.duplicateInvoice(invoice.cdInvoice)
        router.closeInvoiceDetailsOnDuplication()
    }

    func backTapped() {
        InvoiceDetailsEvent.closeTapped
            .send()
        router.closeInvoiceDetails()
    }

    func previewTapped() {
        InvoiceDetailsEvent.previewTapped
            .send()
        router.openPreview(input: invoice)
    }

    func deleteInvoiceTapped() {
        InvoiceDetailsEvent.deleteInvoiceTapped
            .send()
        databaseManager.deleteInvoice(with: invoice.id)
        router.closeInvoiceDetails()
    }

    func switchPaidStatusTapped(_ value: Bool) {
        InvoiceDetailsEvent.switchPaidStatusTapped(isPaid: value)
            .send()
        databaseManager.markInvoicePaid(invoice.cdInvoice, isPaid: value)
    }

    func shareTapped() {
        HapticPlayer.fire(.soft)
        InvoiceDetailsEvent.shareTapped
            .send()

        performIfPremium { [weak self] in
            self?.shareInvoice()
        } else: { [weak self] in
            self?.router.openPaywall(referrer: .invoiceDetails(feature: .share)) {
                self?.shareInvoice()
            }
        }
    }

    func printTapped() {
        HapticPlayer.fire(.soft)
        InvoiceDetailsEvent.printTapped
            .send()

        performIfPremium { [weak self] in
            self?.printInvoice()
        } else: { [weak self] in
            self?.router.openPaywall(referrer: .invoiceDetails(feature: .print)) {
                self?.printInvoice()
            }
        }
    }

    func duplicateTapped() {
        HapticPlayer.fire(.soft)
        InvoiceDetailsEvent.duplicateTapped
            .send()

        performIfPremium { [weak self] in
            self?.duplicateInvoice()
        } else: { [weak self] in
            self?.router.openPaywall(referrer: .invoiceDetails(feature: .duplication)) {
                self?.duplicateInvoice()
            }
        }
    }

    func editTapped() {
        InvoiceDetailsEvent.editTapped
            .send()
        router.openEditInvoice(invoice: invoice)
    }
}

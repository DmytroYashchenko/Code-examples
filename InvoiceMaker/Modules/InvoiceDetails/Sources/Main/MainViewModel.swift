import CombineExt
import Depin
import Foundation

@MainActor
protocol InvoiceDuplicationToastPresenter: AnyObject {

    func presentEventDuplicatedToast()
}

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Injected properties

    @Injected private var appStorage: AppStorage
    @Injected var databaseManager: DatabaseManager
    private let router: MainRouter

    // MARK: - Public properties

    @Published var tab: MainView.Tab = .all
    @Published private var allInvoices: [Invoice] = []
    @Published var invoiceDuplicatedToastIsShown = false
    @Published var isPremium = true

    var invoices: [Invoice] {
        switch tab {
        case .all:
            allInvoices
        case .paid:
            allInvoices.filter { $0.isPaid }
        case .unpaid:
            allInvoices.filter { !$0.isPaid }
        }
    }

    var total: String {
        invoices.totalBreakdown
    }

    // MARK: - Private properties

    private var bag = CancelBag()

    init(router: MainRouter) {
        self.router = router

        MainEvent.screenShown
            .send()

        bind()
    }

    private func bind() {
        databaseManager.$invoices
            .map { $0.map(Invoice.init) }
            .sink { [weak self] in
                self?.allInvoices = $0
            }
            .store(in: &bag)

        $tab
            .dropFirst()
            .map { tab -> MainEvent.PickerValue in
                switch tab {
                case .all:
                        .all
                case .paid:
                        .paid
                case .unpaid:
                        .unpaid
                }
            }
            .sink {
                MainEvent.pickerChanged(value: $0)
                    .send()
            }
            .store(in: &bag)

        appStorage.$isPremium
            .assign(to: &$isPremium)
    }

    func openInvoiceDetails(for invoice: Invoice) {
        MainEvent.invoiceDetailsTapped
            .send()
        router.openInvoiceDetails(
            invoice: invoice,
            invoiceDuplicationToastPresenter: self
        )
    }

    func openCreateInvoice() {
        MainEvent.createInvoiceTapped
            .send()

        router.openInvoiceCreation()
    }

    func markAsPaid(invoice: Invoice) {
        MainEvent.markAsPaidTapped
            .send()

        databaseManager.markInvoicePaid(invoice.cdInvoice, isPaid: true)
    }

    func markAsUnpaid(invoice: Invoice) {
        MainEvent.markUsUnpaidTapped
            .send()

        databaseManager.markInvoicePaid(invoice.cdInvoice, isPaid: false)
    }

    func delete(invoice: Invoice) {
        MainEvent.deleteTapped
            .send()

        databaseManager.deleteInvoice(with: invoice.id)
    }

    func duplicate(invoice: Invoice) {
        MainEvent.duplicateTapped
            .send()

        performIfPremium { [weak self] in
            self?.performInvoiceDuplication(invoice)
        } else: { [weak self] in
            self?.router.openPaywall {
                self?.performInvoiceDuplication(invoice)
            }
        }
    }

    func openPaywall() {
        MainEvent.crownTapped
            .send()
        router.openPaywall { }
    }

    private func performInvoiceDuplication(_ invoice: Invoice) {
        databaseManager.duplicateInvoice(invoice.cdInvoice)
        presentEventDuplicatedToast()
    }
}

extension MainViewModel: InvoiceDuplicationToastPresenter {

    func presentEventDuplicatedToast() {
        invoiceDuplicatedToastIsShown = true
    }
}

import CombineExt
import Core
import Depin
import Foundation

@MainActor
class CreateInvoiceViewModel: ObservableObject {

    // MARK: - Injected properties

    @Injected private var appStorage: AppStorage
    @Injected private var databaseManager: DatabaseManager

    @Storage(CurrencyStorageKey.self) var currency

    private let router: CreateInvoiceRouter
    private var bag = CancelBag()

    private let emptyBuilder = InvoiceBuilder.empty
    @Published var builder = InvoiceBuilder()
    @Published var itemAlreadyAddedToastIsShown = false
    @Published var paymentMethodAlreadyAddedToastIsShown = false

    private var isEdited: Bool {
        emptyBuilder != builder
    }

    init(router: CreateInvoiceRouter) {
        self.router = router

        CreateInvoiceEvent.screenShown
            .send()

        bind()
    }

    private func bind() {
        _currency.publisher.sink { [weak self] in
            self?.builder.currency = $0
        }
        .store(in: &bag)

        databaseManager.$uniqueWorkItems
            .map { $0.map { WorkItem($0) } }
            .sink { [weak self] workItems in
                guard let self else { return }
                let snapshotByID = Dictionary(uniqueKeysWithValues: workItems.map { ($0.id, $0) })
                builder.workItems = builder.workItems.compactMap { snapshotByID[$0.id] }
            }
            .store(in: &bag)

        databaseManager.$uniquePaymentMethods
            .map { $0.map(\.paymentMethod).map { AnyPaymentMethod($0) } }
            .sink { [weak self] paymentMethods in
                guard let self else { return }
                let snapshotByID = Dictionary(uniqueKeysWithValues: paymentMethods.map { ($0.id, $0) })
                builder.invoicePaymentMethods = builder.invoicePaymentMethods.compactMap { snapshotByID[$0.id] }
            }
            .store(in: &bag)
    }

    func cancelTapped() {
        CreateInvoiceEvent.closeTapped
            .send()

//        if isEdited {
//            performIfPremium { [weak self] in
//                self?.createInvoice()
//            }
//        }

        router.close()
    }

    func previewTapped() {
        CreateInvoiceEvent.previewTapped
            .send()
        router.openPreview(input: builder)
    }

    func issuerTapped() {
        CreateInvoiceEvent.issuerTapped
            .send()
        router.openBusinessesList { [unowned self] in
            self.builder.issuer = $0
        }
    }

    func clientTapped() {
        CreateInvoiceEvent.closeTapped
            .send()
        router.openClientsList { [unowned self] in
            self.builder.recipient = $0
        }
    }

    func addItemTapped() {
        CreateInvoiceEvent.addWorkItemTapped
            .send()
        router.openWorkItemsList { [unowned self] workItem in
            guard !builder.workItems.contains(where: { $0.id == workItem.id }) else {
                itemAlreadyAddedToastIsShown = true
                return
            }
            builder.workItems.append(workItem)
        }
    }

    func itemTapped(_ item: WorkItem) {
        CreateInvoiceEvent.workItemTapped
            .send()
        router.openEditWorkItem(
            item: item,
            onRemoveHandler: { [unowned self] workItem in
                builder.workItems = builder.workItems.filter { $0.id != workItem.id }
            }
        )
    }

    func removeWorkItem(_ item: WorkItem) {
        CreateInvoiceEvent.removeWorkItemTapped
            .send()
        builder.workItems = builder.workItems.filter { $0.id != item.id }
    }

    func addPaymentMethodTapped() {
        CreateInvoiceEvent.addPaymentMethodTapped
            .send()
        router.openPaymentMethodsList { [unowned self] paymentMethod in
            guard !builder.paymentMethods.contains(where: { $0.id == paymentMethod.id }) else {
                paymentMethodAlreadyAddedToastIsShown = true
                return
            }
            builder.invoicePaymentMethods.append(AnyPaymentMethod(paymentMethod))
        }
    }

    func paymentMethodTapped(_ paymentMethod: any PaymentMethod) {
        CreateInvoiceEvent.paymentMethodTapped
            .send()
        router.openEditPaymentMethod(paymentMethod: paymentMethod)
    }

    func removePaymentMethod(_ paymentMethod: any PaymentMethod) {
        CreateInvoiceEvent.removePaymentMethodTapped
            .send()
        builder.invoicePaymentMethods = builder.invoicePaymentMethods.filter { $0.id != paymentMethod.id }
    }

    func currencyTapped() {
        CreateInvoiceEvent.currencyTapped
            .send()
        router.openCurrencies()
    }

    func discountTapped() {
        CreateInvoiceEvent.discountTapped
            .send()
        router.openDiscount(
            builder.discount,
            selectionHandler: { [unowned self] in
                builder.discount = $0
            }
        )
    }

    func taxTapped() {
        CreateInvoiceEvent.taxTapped
            .send()
        router.openTax(
            builder.tax,
            selectionHandler: { [unowned self] in
                builder.tax = $0
            }
        )
    }

    func styleTapped() {
        CreateInvoiceEvent.styleTapped
            .send()
        router.openStyles(
            input: builder,
            selectionHandler: { [unowned self] in
                builder.style = $0
            }
        )
    }

    func createInvoiceTapped() {
        HapticPlayer.fire(.soft)
        CreateInvoiceEvent.createInvoiceTapped
            .send()

        if appStorage.isInvoiceDemoCreationUsed {
            performIfPremium { [weak self] in
                self?.createInvoice()
            } else: { [weak self] in
                self?.router.openPaywall {
                    self?.createInvoice()
                }
            }
        } else {
            createInvoice()
        }
    }

    private func createInvoice() {
        appStorage.isInvoiceDemoCreationUsed = true
        databaseManager.createInvoice(with: builder)
        router.close()
        FeedbackService.requestFeatureReview()
    }
}

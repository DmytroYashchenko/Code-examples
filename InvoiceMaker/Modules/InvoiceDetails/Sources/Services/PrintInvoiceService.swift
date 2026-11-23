import Depin
import UIKit

class PrintInvoiceService {

    @Injected private var invoiceRenderingService: InvoiceRenderingService

    func print(_ invoice: Invoice, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let pdfData = invoiceRenderingService.renderInvoice(from: invoice)

            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = .general
            printInfo.jobName = "Invoice"
            printController.printInfo = printInfo
            printController.showsNumberOfCopies = true
            printController.printingItem = pdfData

            DispatchQueue.main.async {
                printController.present(animated: true)
                completion?()
            }
        }
    }
}

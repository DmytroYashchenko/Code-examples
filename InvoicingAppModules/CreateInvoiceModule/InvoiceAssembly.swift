import Depin
import FoundationExt

class InvoiceAssembly: Assembly {

    func assemble(container: Container) {
        container.register(InvoiceRenderingService.self) {
            InvoiceRenderingService()
        }
        .inObjectScope(.container)

        container.register(ShareInvoiceService.self) {
            ShareInvoiceService()
        }
        .inObjectScope(.container)

        container.register(PrintInvoiceService.self) {
            PrintInvoiceService()
        }
        .inObjectScope(.container)
    }
}

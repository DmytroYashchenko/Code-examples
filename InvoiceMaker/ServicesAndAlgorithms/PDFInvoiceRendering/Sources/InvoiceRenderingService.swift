import Foundation

class InvoiceRenderingService {

    func renderInvoice(from input: InvoiceInput) -> Data {
        var renderer: InvoiceRenderable {
            switch input.style.sample {
            case .classic:
                CommonInvoiceRenderer(colorizer: input.style.theme)
            }
        }
        return renderer.render(from: input)
    }
}

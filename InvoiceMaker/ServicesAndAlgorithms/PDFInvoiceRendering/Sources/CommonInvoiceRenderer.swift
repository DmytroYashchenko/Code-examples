import UIKit

protocol InvoiceRenderable {

    func render(from input: InvoiceInput) -> Data
}

class CommonInvoiceRenderer: InvoiceRenderable {

    let colorizer: InvoiceColorizer

    init(colorizer: InvoiceColorizer) {
        self.colorizer = colorizer
    }

    func render(from input: InvoiceInput) -> Data {
        let renderer = CommonPDFRenderer(
            input: input,
            metrics: InvoicePageMetrics(
                pageFormat: .usLetter,
                margin: 36,
                lineHeight: 18,
                bottomMargin: 48
            ),
            currencyFormatter: {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.currencyCode = input.currency.code
                numberFormatter.currencySymbol = input.currency.symbol
                numberFormatter.maximumFractionDigits = 2
                return numberFormatter
            }(),
            textColor: colorizer.textColor,
            tableBorderColor: colorizer.tableBorderColor,
            headersFillColor: colorizer.headersFillColor
        )

        return renderer.render()
    }
}

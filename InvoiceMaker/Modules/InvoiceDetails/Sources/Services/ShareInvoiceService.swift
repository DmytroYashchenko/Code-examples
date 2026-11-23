import Depin
import Foundation
import UIKitExt

class ShareInvoiceService {

    @Injected private var invoiceRenderingService: InvoiceRenderingService

    private let fileManager = FileManager.default

    func share(_ invoice: Invoice, completion: (() -> Void)? = nil) {
        let fileURL = makeFileURL(for: invoice)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let pdfData = invoiceRenderingService.renderInvoice(from: invoice)

            guard (try? pdfData.write(to: fileURL)) != nil else {
                completion?()
                return
            }

            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            activityViewController.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]

            activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
                self?.cleanTempFile(fileURL)
            }

            DispatchQueue.main.async {
                UIApplication
                    .keyWindow?
                    .rootViewController?
                    .present(
                        activityViewController,
                        animated: true,
                        completion: {
                            completion?()
                        }
                    )
            }
        }
    }
}

// MARK: - Private methods

private extension ShareInvoiceService {

    func makeFileURL(for invoice: Invoice) -> URL {
        let fileName = [
            "Invoice",
            invoice.issuer?.name,
            invoice.recipient?.name,
            invoice.number
        ]
            .compactMap { $0?.sanitizedForFilename() }
            .joined(separator: "_")
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)

        return fileManager
            .temporaryDirectory
            .appendingPathComponent("\(fileName).pdf")
    }

    func cleanTempFile(_ fileURL: URL) {
        try? fileManager.removeItem(at: fileURL)
    }
}

private extension String {
    func sanitizedForFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
    }
}

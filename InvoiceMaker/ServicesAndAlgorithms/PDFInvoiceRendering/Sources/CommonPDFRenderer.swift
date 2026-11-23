import PDFKit
import SwiftUI
import UIKit

class CommonPDFRenderer: UIGraphicsPDFRenderer {

    enum Column: String, CaseIterable {

        case description = "Description"
        case quantity = "QTY"
        case price = "Price"
        case amount = "Amount"

        var headerTitle: String {
            rawValue
        }

        var widthMultiplier: CGFloat {
            switch self {
            case .description:
                0.46
            case .quantity:
                0.12
            case .price:
                0.20
            case .amount:
                0.22
            }
        }

        func width(with metrics: InvoicePageMetrics) -> CGFloat {
            metrics.contentWidth * widthMultiplier
        }
    }

    let input: InvoiceInput
    let metrics: InvoicePageMetrics
    let currencyFormatter: NumberFormatter

    let textColor: UIColor
    let tableBorderColor: UIColor
    let headersFillColor: UIColor

    private lazy var totals = input.totals
    private var renderableHeight: CGFloat = 0

    init(
        input: InvoiceInput,
        metrics: InvoicePageMetrics,
        currencyFormatter: NumberFormatter,
        textColor: UIColor,
        tableBorderColor: UIColor,
        headersFillColor: UIColor
    ) {
        self.input = input
        self.metrics = metrics
        self.currencyFormatter = currencyFormatter
        self.textColor = textColor
        self.tableBorderColor = tableBorderColor
        self.headersFillColor = headersFillColor

        super.init(
            bounds: CGRect(
                x: .zero,
                y: .zero,
                width: metrics.pageWidth,
                height: metrics.pageHeight
            ),
            format: .init()
        )
    }

    func render() -> Data {
        // Instead of multipage invoice, currently we use single page rendering, when page height adjusts to current
        // renderable content height. To achieve this approach, firstly we need to calculate content height, so we
        // call renderingActions method with empty context, just to launch rendering and set renderableHeight property
        // when rendering finishes.
        renderingActions(UIGraphicsPDFRendererContext())

        // And now, when we've definitely determined renderable content height, we create actual UIGraphicsPDFRenderer
        // with calculated content height, and start our invoice rendering.
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(
                origin: .zero,
                size: CGSize(
                    width: metrics.pageWidth,
                    height: renderableHeight
                )
            )
        )
        return renderer.pdfData(actions: renderingActions)
    }

    private lazy var renderingActions: ((UIGraphicsPDFRendererContext) -> Void) = { [weak self] context in
        guard let self else { return }

        // MARK: - Page creation

        context.beginPage()
        let interBlockSpacing: CGFloat = 18
        var currentY = metrics.margin

        // MARK: - Invoice meta block

        let metaBlockX = metrics.margin
        let metaBlockMaxWidth = metrics.contentWidth * 0.5

        drawText(
            "INVOICE",
            font: .boldSystemFont(ofSize: 18),
            at: CGPoint(x: metaBlockX, y: currentY),
            maxWidth: metaBlockMaxWidth
        )
        currentY += metrics.lineHeight + 4

        if let number = input.number {
            let numberHeight = drawText(
                "#\(number)",
                font: .systemFont(ofSize: 11),
                at: CGPoint(x: metaBlockX, y: currentY),
                maxWidth: metaBlockMaxWidth,
                verticalPadding: 4
            )
            currentY += numberHeight
        }

        let issuedDateTitle = input.issuedDate.formatted(date: .long, time: .omitted)
        drawText(
            "Issued \(issuedDateTitle)",
            font: .systemFont(ofSize: 11),
            at: CGPoint(x: metaBlockX, y: currentY),
            maxWidth: metaBlockMaxWidth
        )
        currentY += metrics.lineHeight

        if input.dueDate != .noDueDate {
            let dueDateTitle = input.dueDate.receiptDateTitle(from: input.issuedDate)
            drawText(
                dueDateTitle,
                font: .systemFont(ofSize: 11),
                at: CGPoint(x: metaBlockX, y: currentY),
                maxWidth: metaBlockMaxWidth
            )
            currentY += metrics.lineHeight
        }

        currentY += interBlockSpacing

        // MARK: - FROM / BILL TO blocks
        let partyBlocksSpacing = metrics.margin
        let partyBlockWidth = (metrics.pageWidth - (metrics.margin * 2 + partyBlocksSpacing)) / 2

        drawText(
            "FROM",
            font: .boldSystemFont(ofSize: 10),
            at: CGPoint(x: metrics.margin, y: currentY)
        )

        drawText(
            "BILL TO",
            font: .boldSystemFont(ofSize: 10),
            at: CGPoint(x: metrics.margin + partyBlocksSpacing + partyBlockWidth, y: currentY)
        )
        currentY += metrics.lineHeight

        let issuerBlockHeight = drawIssuer(
            input.issuer,
            at: CGPoint(x: metrics.margin, y: currentY),
            width: partyBlockWidth
        )
        let recipientBlockHeight = drawRecipient(
            input.recipient,
            at: CGPoint(x: metrics.margin + partyBlocksSpacing + partyBlockWidth, y: currentY),
            width: partyBlockWidth
        )
        currentY += max(issuerBlockHeight, recipientBlockHeight) + interBlockSpacing

        // MARK: - Work Items Table

        drawTableHeader(in: context.cgContext, y: &currentY)

        let descriptionColumnWidth = Column.description.width(with: metrics)
        let quantityColumnWidth = Column.quantity.width(with: metrics)
        let priceColumnWidth = Column.price.width(with: metrics)
        let amountColumnWidth = Column.amount.width(with: metrics)

        for item in input.workItems {
            var y = currentY
            var x = metrics.margin

            // Description (+ optional note)
            let nameHeight = drawText(
                item.name,
                font: .boldSystemFont(ofSize: 12),
                at: CGPoint(x: x + 4, y: y),
                maxWidth: descriptionColumnWidth,
                verticalPadding: 2
            )
            y += nameHeight

            if let description = item.itemDescription, !description.isEmpty {
                let descriptionHeight = drawText(
                    description,
                    font: .systemFont(ofSize: 11),
                    at: CGPoint(x: x + 4, y: y),
                    maxWidth: descriptionColumnWidth,
                    verticalPadding: 2
                )
                y += descriptionHeight
            }
            if let discount = item.discount {
                let discountTitle: String
                switch discount {
                case let .percentage(value):
                    discountTitle = "Incl. \(value)% discount"
                case let .fixed(amount):
                    let discountAmount = currencyFormatter.string(from: NSNumber(value: amount)) ?? ""
                    discountTitle = "Incl. \(discountAmount) Discount"
                }

                drawText(
                    discountTitle,
                    color: textColor.withAlphaComponent(0.6),
                    font: .systemFont(ofSize: 11),
                    at: CGPoint(x: x + 4, y: y),
                    maxWidth: descriptionColumnWidth
                )
                y += metrics.lineHeight
            }
            x += descriptionColumnWidth

            // Quantity
            drawText(
                String(format: "%.1f", Double(item.quantity)),
                at: CGPoint(x: x - 4, y: currentY),
                align: .right,
                maxWidth: quantityColumnWidth
            )
            x += quantityColumnWidth

            // Price
            drawText(
                currencyFormatter.string(from: NSNumber(value: item.price)) ?? "",
                at: CGPoint(x: x - 4, y: currentY),
                align: .right,
                maxWidth: priceColumnWidth
            )
            x += priceColumnWidth

            // Amount
            drawText(
                currencyFormatter.string(from: NSNumber(value: item.amount)) ?? "",
                at: CGPoint(x: x - 4, y: currentY),
                align: .right,
                maxWidth: amountColumnWidth
            )

            // Draw border lines
            let cgContext = context.cgContext

            cgContext.setStrokeColor(tableBorderColor.cgColor)
            cgContext.setLineWidth(0.5)

            // Top border
            cgContext.move(to: CGPoint(x: metrics.margin, y: currentY))
            cgContext.addLine(to: CGPoint(x: metrics.pageWidth - metrics.margin, y: currentY))

            // Bottom border
            cgContext.move(to: CGPoint(x: metrics.margin, y: y))
            cgContext.addLine(to: CGPoint(x: metrics.pageWidth - metrics.margin, y: y))

            // Vertical column lines
            x = metrics.margin
            Column.allCases
                .map { $0.width(with: self.metrics) }
                .forEach { width in
                    cgContext.move(to: CGPoint(x: x, y: currentY))
                    cgContext.addLine(to: CGPoint(x: x, y: y))
                    x += width
                }
            cgContext.move(to: CGPoint(x: x, y: currentY))
            cgContext.addLine(to: CGPoint(x: x, y: y))

            cgContext.strokePath()
            let rowHeight = y - currentY
            currentY += rowHeight
        }

        // MARK: - Summary

        currentY += interBlockSpacing

        drawSummaryRow(
            title: "Subtotal",
            amount: totals.subtotal,
            font: .boldSystemFont(ofSize: 12),
            currentY: &currentY,
            priceColumnWidth: priceColumnWidth,
            amountColumnWidth: amountColumnWidth,
            context: context.cgContext
        )
        if totals.discountValue > 0 {
            drawSummaryRow(
                title: totals.discountTitle,
                amount: -totals.discountValue,
                font: .systemFont(ofSize: 12),
                currentY: &currentY,
                priceColumnWidth: priceColumnWidth,
                amountColumnWidth: amountColumnWidth,
                context: context.cgContext
            )
        }
        if totals.taxValue > 0 {
            drawSummaryRow(
                title: totals.taxTitle,
                amount: totals.taxValue,
                font: .systemFont(ofSize: 12),
                currentY: &currentY,
                priceColumnWidth: priceColumnWidth,
                amountColumnWidth: amountColumnWidth,
                context: context.cgContext
            )
        }
        drawSummaryRow(
            title: "Total",
            amount: totals.total,
            font: .boldSystemFont(ofSize: 13),
            isBordered: false,
            currentY: &currentY,
            priceColumnWidth: priceColumnWidth,
            amountColumnWidth: amountColumnWidth,
            context: context.cgContext
        )

        // MARK: - Signature

        if let signature = input.signature {
            currentY += interBlockSpacing
            drawSignature(
                signature,
                at: CGPoint(
                    x: metrics.pageWidth - metrics.margin - amountColumnWidth,
                    y: currentY
                ),
                currentY: &currentY,
                context: context.cgContext
            )
        } else {
            currentY += interBlockSpacing * 3
        }

        // MARK: - Notes

        if let notes = input.notes, !notes.isEmpty {
            drawText(
                "NOTES",
                font: .boldSystemFont(ofSize: 10),
                at: CGPoint(x: metrics.margin, y: currentY),
                maxWidth: metrics.contentWidth
            )
            currentY += metrics.lineHeight

            let notesHeight = drawText(
                notes,
                font: .systemFont(ofSize: 10),
                at: CGPoint(x: metrics.margin, y: currentY),
                maxWidth: metrics.contentWidth,
                verticalPadding: 2
            )
            currentY += notesHeight
        }

        // MARK: - Payment methods

        if !input.paymentMethods.isEmpty {
            currentY += metrics.lineHeight
            drawSeparator(
                in: context.cgContext,
                at: CGPoint(x: metrics.margin, y: currentY),
                width: metrics.contentWidth
            )
            currentY += metrics.lineHeight

            drawText(
                "PAYMENT OPTIONS",
                font: .boldSystemFont(ofSize: 10),
                at: CGPoint(x: metrics.margin, y: currentY),
                maxWidth: metrics.contentWidth
            )
            currentY += metrics.lineHeight

            let itemWidth = metrics.contentWidth / 2
            input.paymentMethods.enumerated().forEach { index, method in
                let titleHeight = self.drawText(
                    "⦿ \(method.renderingTitle)",
                    font: .boldSystemFont(ofSize: 12),
                    at: CGPoint(x: self.metrics.margin, y: currentY),
                    maxWidth: itemWidth,
                    verticalPadding: 2
                )
                currentY += titleHeight

                let bodyHeight = self.drawAttributedText(
                    method.renderingBody,
                    at: CGPoint(x: self.metrics.margin, y: currentY),
                    maxWidth: itemWidth,
                    verticalPadding: 2
                )
                currentY += bodyHeight

                if let qrCodeValue = method.renderingQRCodeValue {
                    let qrCodeSize = CGSize(width: 48, height: 48)
                    let qrCodeGenerator = QRCodeGenerator(
                        encodable: qrCodeValue,
                        fillColor: .black,
                        size: qrCodeSize
                    )
                    if let qrCodeImage = qrCodeGenerator.image {
                        let imageHeight = self.drawImage(
                            qrCodeImage,
                            at: CGPoint(x: self.metrics.margin, y: currentY),
                            size: qrCodeSize
                        )
                        currentY += imageHeight
                    }
                }

                if index != self.input.paymentMethods.indices.last {
                    currentY += self.metrics.lineHeight / 2
                }
            }
        }

        // Set global renderable page height (not less given page height)
        renderableHeight = max(currentY + metrics.bottomMargin, metrics.pageHeight)
    }
}

// MARK: - Private methods

private extension CommonPDFRenderer {

    /// Draws text, returns it's height
    @discardableResult
    func drawText(
        _ text: String,
        color: UIColor? = nil,
        font: UIFont = .systemFont(ofSize: 12),
        at point: CGPoint,
        align: NSTextAlignment = .left,
        maxWidth: CGFloat = .greatestFiniteMagnitude,
        verticalPadding: CGFloat = 0
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = align

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color ?? textColor,
            .font: font,
            .paragraphStyle: paragraph
        ]

        let constraintSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingRect = (text as NSString).boundingRect(
            with: constraintSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        let renderingHeight = boundingRect.height
        let drawingRect = CGRect(
            x: point.x,
            y: point.y + verticalPadding,
            width: maxWidth,
            height: renderingHeight + verticalPadding
        )

        text.draw(
            with: drawingRect,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )

        return renderingHeight + verticalPadding * 2
    }

    /// Draws  attributed text, returns it's height
    @discardableResult
    func drawAttributedText(
        _ text: NSAttributedString,
        color: UIColor? = nil,
        font: UIFont = .systemFont(ofSize: 12),
        at point: CGPoint,
        align: NSTextAlignment = .left,
        maxWidth: CGFloat = .greatestFiniteMagnitude,
        verticalPadding: CGFloat = 0
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = align

        let attributedText = NSMutableAttributedString(attributedString: text)

        // Enumerate and merge existing attributes with new ones
        attributedText.enumerateAttributes(
            in: NSRange(location: 0, length: attributedText.length),
            using: { attributes, range, _ in
                var merged = attributes

                // Paragraph style always applied
                merged[.paragraphStyle] = paragraph

                // Foreground color applied only if not already set
                if merged[.foregroundColor] == nil {
                    merged[.foregroundColor] = color ?? textColor
                }

                // Handle font: preserve bold/italic traits if they exist
                if let existingFont = merged[.font] as? UIFont {
                    // Keep bold/italic if present, but replace family/size with provided font
                    if let newDescriptor = font.fontDescriptor
                        .withSymbolicTraits(existingFont.fontDescriptor.symbolicTraits) {
                        merged[.font] = UIFont(descriptor: newDescriptor, size: font.pointSize)
                    } else {
                        merged[.font] = font
                    }
                } else {
                    merged[.font] = font
                }

                attributedText.setAttributes(merged, range: range)
            }
        )

        let constraintSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingRect = attributedText.boundingRect(
            with: constraintSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        let renderingHeight = boundingRect.height
        let drawingRect = CGRect(
            x: point.x,
            y: point.y + verticalPadding,
            width: maxWidth,
            height: renderingHeight + verticalPadding
        )

        attributedText.draw(
            with: drawingRect,
            options: .usesLineFragmentOrigin,
            context: nil
        )

        return renderingHeight + verticalPadding * 2
    }

    /// Draw image, returns it's height
    @discardableResult
    func drawImage(
        _ image: UIImage,
        at point: CGPoint,
        size: CGSize
    ) -> CGFloat {
        image.draw(in: CGRect(
            x: point.x,
            y: point.y,
            width: size.width,
            height: size.height
        ))
        return size.height
    }

    /// Draws issuer, returns block total height
    func drawIssuer(
        _ issuer: Business?,
        at point: CGPoint,
        width: CGFloat
    ) -> CGFloat {
        guard let issuer else { return 0 }

        let x = point.x
        var y = point.y

        let nameHeight = drawText(
            issuer.name,
            font: .boldSystemFont(ofSize: 13),
            at: CGPoint(x: x, y: y),
            maxWidth: width,
            verticalPadding: 2
        )
        y += nameHeight

        if let phoneNumber = issuer.contactPhone {
            let phoneNumberHeight = drawText(
                phoneNumber,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += phoneNumberHeight
        }

        if let email = issuer.contactEmail {
            let emailHeight = drawText(
                email.email,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += emailHeight
        }

        if let address = issuer.contactAddress {
            let addressHeight = drawText(
                address,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += addressHeight
        }

        let partyBlockHeight = y - point.y
        return partyBlockHeight
    }

    /// Draws recipient, returns block total height
    func drawRecipient(
        _ client: Client?,
        at point: CGPoint,
        width: CGFloat
    ) -> CGFloat {
        guard let client else { return 0 }

        let x = point.x
        var y = point.y

        let nameHeight = drawText(
            client.name,
            font: .boldSystemFont(ofSize: 13),
            at: CGPoint(x: x, y: y),
            maxWidth: width,
            verticalPadding: 2
        )
        y += nameHeight

        if let phoneNumber = client.phone {
            let phoneNumberHeight = drawText(
                phoneNumber,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += phoneNumberHeight
        }

        if let email = client.email {
            let emailHeight = drawText(
                email.email,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += emailHeight
        }

        if let address = client.address {
            let addressHeight = drawText(
                address,
                at: CGPoint(x: x, y: y),
                maxWidth: width,
                verticalPadding: 2
            )
            y += addressHeight
        }

        let partyBlockHeight = y - point.y
        return partyBlockHeight
    }

    /// Draws summary's title and amount in a row
    func drawSummaryRow(
        title: String,
        amount: Double,
        font: UIFont,
        isBordered: Bool = true,
        currentY: inout CGFloat,
        priceColumnWidth: CGFloat,
        amountColumnWidth: CGFloat,
        context: CGContext
    ) {
        let mostRightX = metrics.pageWidth - metrics.margin
        let mostLeftX = mostRightX - priceColumnWidth - amountColumnWidth

        drawText(
            title,
            font: font,
            at: CGPoint(x: mostLeftX - 4, y: currentY),
            align: .right,
            maxWidth: priceColumnWidth
        )
        drawText(
            currencyFormatter.string(from: NSNumber(value: amount)) ?? "",
            font: font,
            at: CGPoint(x: mostLeftX + priceColumnWidth - 4, y: currentY),
            align: .right,
            maxWidth: amountColumnWidth
        )

        guard isBordered else {
            currentY += metrics.lineHeight
            return
        }

        // Draw border lines
        context.setStrokeColor(tableBorderColor.cgColor)
        context.setLineWidth(0.5)

        // Top border
        context.move(to: CGPoint(x: mostLeftX, y: currentY))
        context.addLine(to: CGPoint(x: mostRightX, y: currentY))

        // Bottom border
        context.move(to: CGPoint(x: mostLeftX, y: currentY + metrics.lineHeight))
        context.addLine(to: CGPoint(x: mostRightX, y: currentY + metrics.lineHeight))

        // Vertical borders
        let topY = currentY
        let bottomY = currentY + metrics.lineHeight

        context.move(to: CGPoint(x: mostLeftX, y: topY))
        context.addLine(to: CGPoint(x: mostLeftX, y: bottomY))

        context.move(to: CGPoint(x: mostLeftX + priceColumnWidth, y: topY))
        context.addLine(to: CGPoint(x: mostLeftX + priceColumnWidth, y: bottomY))

        context.move(to: CGPoint(x: mostRightX, y: topY))
        context.addLine(to: CGPoint(x: mostRightX, y: bottomY))

        context.strokePath()
        currentY += metrics.lineHeight
    }

    /// Draws signature
    func drawSignature(
        _ signature: UIImage,
        at point: CGPoint,
        currentY: inout CGFloat,
        context: CGContext
    ) {
        let maxWidth: CGFloat = 140
        let maxHeight: CGFloat = 70

        let signatureSize = signature.size
        let aspectRatio = signatureSize.width / signatureSize.height

        var renderWidth = maxWidth
        var renderHeight = renderWidth / aspectRatio

        if renderHeight > maxHeight {
            renderHeight = maxHeight
            renderWidth = renderHeight * aspectRatio
        }

        let x = point.x - renderWidth / 2
        drawImage(
            signature,
            at: CGPoint(
                x: x,
                y: point.y
            ),
            size: .init(width: renderWidth, height: renderHeight)
        )

        context.setStrokeColor(tableBorderColor.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(0.5)

        let lineY = currentY + renderHeight + 2
        context.move(to: CGPoint(x: x, y: lineY))
        context.addLine(to: CGPoint(x: x + renderWidth, y: lineY))

        context.strokePath()
        currentY += renderHeight
    }

    /// Draws table header
    func drawTableHeader(
        in context: CGContext,
        y: inout CGFloat
    ) {
        let columns = Column.allCases

        // Draw header background
        let headerHeight = metrics.lineHeight + 6
        let headerRect = CGRect(
            x: metrics.margin,
            y: y,
            width: metrics.contentWidth,
            height: headerHeight
        )
        context.setFillColor(headersFillColor.cgColor)
        context.fill(headerRect)

        // Draw column titles
        var x = metrics.margin
        columns.enumerated().forEach { index, column in
            let columnWidth = column.width(with: metrics)
            drawText(
                column.headerTitle,
                font: .boldSystemFont(ofSize: 11),
                at: CGPoint(x: x + 4, y: y + 4),
                align: (index == 0 ? .left : .right),
                maxWidth: columnWidth - 8
            )
            x += columnWidth
        }

        // Draw border lines
        context.setStrokeColor(tableBorderColor.cgColor)
        context.setLineWidth(0.5)

        // Top border
        context.move(to: CGPoint(x: metrics.margin, y: y))
        context.addLine(to: CGPoint(x: metrics.pageWidth - metrics.margin, y: y))

        // Bottom border
        context.move(to: CGPoint(x: metrics.margin, y: y + headerHeight))
        context.addLine(to: CGPoint(x: metrics.pageWidth - metrics.margin, y: y + headerHeight))

        // Vertical column lines
        x = metrics.margin
        columns.map { $0.width(with: metrics) }
            .forEach { width in
                context.move(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(x: x, y: y + headerHeight))
                x += width
            }
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: y + headerHeight))

        context.strokePath()
        y += headerHeight
    }

    func drawSeparator(
        in context: CGContext,
        at point: CGPoint,
        width: CGFloat
    ) {
        context.setStrokeColor(tableBorderColor.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(0.5)

        context.move(to: point)
        context.addLine(to: CGPoint(x: point.x + width, y: point.y))
        context.strokePath()
    }
}

// MARK: - Preview

struct PDFInvoicePreview: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

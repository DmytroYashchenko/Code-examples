import Foundation
import UIKit

protocol InvoiceInput {

    var number: String? { get }

    var issuedDate: Date { get }
    var dueDate: DueDate { get }

    var issuer: Business? { get }
    var recipient: Client? { get }

    var workItems: [WorkItem] { get }
    var currency: Currency { get }
    var discount: DiscountType? { get }
    var tax: TaxType? { get }

    var paymentMethods: [any PaymentMethod] { get }
    var notes: String? { get }

    var totals: InvoiceTotals { get }
    var signature: UIImage? { get }
    var style: InvoiceStyle { get set }
}

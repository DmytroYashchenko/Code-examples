import UIKit

protocol InvoiceColorizer: Codable {

    var textColor: UIColor { get }
    var tableBorderColor: UIColor { get }
    var headersFillColor: UIColor { get }

    var id: String { get }
    var displayName: String { get }
}

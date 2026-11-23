enum InvoiceSample: Codable, CaseIterable, Identifiable, Hashable {

    static var `default`: Self = .classic

    case classic

    var displayName: String {
        switch self {
        case .classic:
            "Classic"
        }
    }

    var availableThemes: [InvoiceColorizer] {
        switch self {
        case .classic:
            InvoiceClassicTheme.allCases
        }
    }

    var id: String {
        displayName
    }
}

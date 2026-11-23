import SwiftUI
import UIKitExt

enum InvoiceClassicTheme: String, Codable, CaseIterable, Identifiable {

    case office
    case modernBlue
    case freelanceWarm
    case evelyn
    case ecoMinimal
    case luxuryBlackAndGold

    var id: String {
        String(reflecting: Self.self) + "_" + rawValue
    }

    var displayName: String {
        rawValue
    }
}

extension InvoiceClassicTheme: InvoiceColorizer {

    var textColor: UIColor {
        switch self {
        case .office:
            UIColor(hex: "000000")
        case .modernBlue:
            UIColor(hex: "1F3C88")
        case .freelanceWarm:
            UIColor(hex: "4A2E05")
        case .evelyn:
            UIColor(hex: "290446")
        case .ecoMinimal:
            UIColor(hex: "2F4F4F")
        case .luxuryBlackAndGold:
            UIColor(hex: "2C2C2C")
        }
    }

    var tableBorderColor: UIColor {
        switch self {
        case .office:
            UIColor(hex: "9E9E9E")
        case .modernBlue:
            UIColor(hex: "B8C6E0")
        case .freelanceWarm:
            UIColor(hex: "C6A664")
        case .evelyn:
            UIColor(hex: "995DC5")
        case .ecoMinimal:
            UIColor(hex: "7BAE7F")
        case .luxuryBlackAndGold:
            UIColor(hex: "C9A227")
        }
    }

    var headersFillColor: UIColor {
        switch self {
        case .office:
            UIColor(hex: "F2F2F2")
        case .modernBlue:
            UIColor(hex: "E8EEFA")
        case .freelanceWarm:
            UIColor(hex: "FFF6E5")
        case .evelyn:
            UIColor(hex: "DFD4E8")
        case .ecoMinimal:
            UIColor(hex: "E8F3E8")
        case .luxuryBlackAndGold:
            UIColor(hex: "FFF8E1")
        }
    }
}

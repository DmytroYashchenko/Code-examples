import Foundation

enum StorageTextFormatter {

    static func string(for bytes: Int64) -> String {
        guard bytes > 0 else { return String(localized: "0 GB") }

        let gigabyte = 1_000_000_000.0
        let megabyte = 1_000_000.0

        if Double(bytes) >= gigabyte {
            let value = Double(bytes) / gigabyte
            let precision = value >= 10 ? 1 : 2
            let formattedValue = value.formatted(.number.precision(.fractionLength(precision)))
            return "\(formattedValue) \(String(localized: "GB"))"
        }

        let value = Double(bytes) / megabyte
        let formattedValue = value.formatted(.number.precision(.fractionLength(0)))
        return "\(formattedValue) \(String(localized: "MB"))"
    }
}

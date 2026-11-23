struct InvoiceStyle: Codable, Equatable {

    static var `default`: Self {
        let defaultSample: InvoiceSample = .classic
        return Self(
            sample: defaultSample,
            themeId: defaultSample.availableThemes.first!.id
        )
    }

    let sample: InvoiceSample
    let themeId: String

    var displayName: String {
        sample.displayName
    }

    var theme: InvoiceColorizer {
        sample.availableThemes.first { $0.id == themeId } ?? sample.availableThemes.first!
    }
}

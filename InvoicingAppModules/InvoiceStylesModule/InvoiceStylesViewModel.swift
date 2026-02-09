import Combine
import Depin
import Foundation

@MainActor
class InvoiceStylesViewModel: ObservableObject {

    // MARK: - Injected properties

    @Injected private var invoiceRenderingService: InvoiceRenderingService

    private let router: InvoiceStylesRouter
    private let input: InvoiceInput
    private let onStyleSelected: (InvoiceStyle) -> Void

    @Published private(set) var selectedSample: InvoiceSample
    @Published private var selectedThemesId = [InvoiceSample: String]()

    var selectableSamples = InvoiceSample.allCases

    var selectableThemes: [InvoiceColorizer] {
        selectedSample.availableThemes
    }

    var selectedThemeId: String {
        selectedThemesId[selectedSample] ?? selectedSample.availableThemes.first!.id
    }

    func previewData(for sample: InvoiceSample) -> Data? {
        guard
            var currentPreviewData = previewDatas[sample],
            let currentThemeId = selectedThemesId[sample]
        else {
            return nil
        }

        if let data = currentPreviewData[currentThemeId] {
            return data
        }
        var input = input
        input.style = .init(sample: sample, themeId: currentThemeId)
        let previewData = invoiceRenderingService.renderInvoice(from: input)

        currentPreviewData[currentThemeId] = previewData
        previewDatas[sample] = currentPreviewData
        return previewData
    }

    private var previewDatas = [InvoiceSample: [String: Data]]()

    init(
        router: InvoiceStylesRouter,
        input: InvoiceInput,
        onStyleSelected: @escaping (InvoiceStyle) -> Void
    ) {
        self.router = router
        self.input = input
        self.onStyleSelected = onStyleSelected
        self.selectedSample = input.style.sample

        InvoiceStylesEvent.screenShown
            .send()

        fillInitialData()
    }

    func selectSample(_ sample: InvoiceSample) {
        InvoiceStylesEvent.sampleSelected(sample: sample)
            .send()
        selectedSample = sample
    }

    func selectTheme(id: String) {
        if let selectedTheme = selectableThemes.first(where: { $0.id == id }) {
            InvoiceStylesEvent.themeSelected(theme: selectedTheme)
                .send()
        }
        selectedThemesId[selectedSample] = id
    }

    func closeTapped() {
        InvoiceStylesEvent.closeTapped
            .send()
        router.closeInvoiceStyles()
    }

    func applyTapped() {
        let selectedStyle = InvoiceStyle(sample: selectedSample, themeId: selectedThemeId)
        InvoiceStylesEvent.styleApplied(style: selectedStyle)
            .send()
        onStyleSelected(selectedStyle)
        router.closeInvoiceStyles()
    }
}

// MARK: - Private methods

private extension InvoiceStylesViewModel {

    func fillInitialData() {
        // Fill preselected theme for each sample
        selectableSamples.forEach { sample in
            let initialThemeId = sample == selectedSample
            ? input.style.themeId // Restore selection from received input
            : sample.availableThemes.first!.id // Otherwise preselected theme is first of available ones

            // Fill preview data for initially selected samples
            var renderingInput = input
            renderingInput.style = .init(sample: sample, themeId: initialThemeId)
            let previewData = invoiceRenderingService.renderInvoice(from: renderingInput)
            previewDatas[sample] = [initialThemeId: previewData]

            // Save initially selected theme for all samples
            selectedThemesId[sample] = initialThemeId
        }
    }
}

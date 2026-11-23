import Combine
import Depin
import Foundation
import SwiftUI

struct CleaningSummaryFlowInput {

    let deletedItemCount: Int
    let deletedBytes: Int64
    let rateUsReferrer: RateUsReferrer?

    init(
        deletedItemCount: Int,
        deletedBytes: Int64,
        rateUsReferrer: RateUsReferrer? = nil
    ) {
        self.deletedItemCount = deletedItemCount
        self.deletedBytes = deletedBytes
        self.rateUsReferrer = rateUsReferrer
    }
}

@MainActor
final class CleaningSummaryViewModel: ObservableObject {

    @Injected private var deviceService: DeviceService

    private let router: HomeRouter
    private let input: CleaningSummaryFlowInput
    private var hasRequestedReview = false

    init(
        router: HomeRouter,
        input: CleaningSummaryFlowInput
    ) {
        self.router = router
        self.input = input
    }

    func onAppear() {
        guard
            !hasRequestedReview,
            let rateUsReferrer = input.rateUsReferrer
        else {
            return
        }

        hasRequestedReview = true
        RateUsService.requestReview(referrer: rateUsReferrer)
    }

    var deletedItemsText: String {
        itemCountText(for: input.deletedItemCount)
    }

    var freedStoragePercentage: Double {
        guard let totalDeviceStorageGB = deviceService.normalizedStorageSizeGB() else {
            return .zero
        }

        let totalDeviceStorageBytes = Double(totalDeviceStorageGB) * 1_000_000_000
        guard totalDeviceStorageBytes > .zero else { return .zero }

        let percentage = (Double(input.deletedBytes) / totalDeviceStorageBytes) * 100
        guard percentage > .zero else { return .zero }

        return min(max(percentage, 0.1), 100)
    }

    var deletedStorageText: String {
        storageText(for: input.deletedBytes)
    }

    var freedStorageText: String {
        "\(freedStoragePercentage.formatted(.number.precision(.fractionLength(0 ... 1))))%"
    }

    func gotItTapped() {
        router.closeCleaningSummaryAndPopToRoot()
    }
}

// MARK: - Private methods

private extension CleaningSummaryViewModel {

    func itemCountText(for count: Int) -> String {
        count == 1
            ? String(localized: "1 item")
            : String(localized: "\(count) items")
    }

    func storageText(for bytes: Int64) -> String {
        StorageTextFormatter.string(for: bytes)
    }
}

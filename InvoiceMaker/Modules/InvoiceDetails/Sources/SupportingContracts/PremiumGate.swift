import Depin
import EventKit
import FoundationExt
import RevenueCat

func performIfPremium(
    premiumAction: @escaping @MainActor () -> Void,
    else forbiddenAction: (@MainActor () -> Void)? = nil
) {
    @Injected var purchaseManager: PurchaseManager
    @Injected var appStorage: AppStorage
    Task {
        await purchaseManager.fetchSubscriptionStatus()
        if await appStorage.isPremium {
            await premiumAction()
        } else {
            await forbiddenAction?()
        }
    }
}

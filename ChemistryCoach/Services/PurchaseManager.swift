import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "com.chemistrycoach.all-experiments"
    // TEMPORARILY UNLOCKED FOR TESTING — set back to `false` to re-enable the paywall
    // once you're happy with the app and ready to turn payment back on.
    @Published private(set) var isPremium = true
    @Published private(set) var product: Product?
    @Published private(set) var errorMessage: String?
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    func refresh() async {
        do { product = try await Product.products(for: [Self.productID]).first } catch { errorMessage = error.localizedDescription }
        for await result in Transaction.currentEntitlements { await handle(result) }
    }

    func purchase() async {
        guard let product else { return }
        do {
            switch try await product.purchase() {
            case .success(let verification): await handle(verification)
            case .userCancelled, .pending: break
            @unknown default: break
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async { await refresh() }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID { isPremium = true }
        await transaction.finish()
    }
}

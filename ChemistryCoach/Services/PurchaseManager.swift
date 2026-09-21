import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "com.chemistrycoach.all-experiments"

    @Published private(set) var isPremium = false
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
        errorMessage = nil
        isPremium = false
        do {
            product = try await Product.products(for: [Self.productID]).first
            if product == nil {
                errorMessage = "Premium product is not available right now."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    func purchase() async {
        guard let product else {
            errorMessage = "The premium product is currently unavailable."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "The purchase could not be completed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async { await refresh() }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            isPremium = transaction.revocationDate == nil && transaction.expirationDate.map { $0 > Date() } ?? true
        }
        await transaction.finish()
    }
}

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @ObservedObject var purchases: PurchaseManager
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill").font(.system(size: 52)).foregroundStyle(.tint)
            Text("Unlock all practical labs").font(.title2.bold())
            Text("Acid–Base Titration stays free. Unlock the remaining experiments with a one-time purchase.").multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let product = purchases.product {
                Button("Unlock for \(product.displayPrice)") { Task { await purchases.purchase() } }.buttonStyle(.borderedProminent)
            } else { ProgressView("Loading purchase…") }
            Button("Restore Purchases") { Task { await purchases.restore() } }.buttonStyle(.bordered)
            if let error = purchases.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }.padding().navigationTitle("Premium")
    }
}

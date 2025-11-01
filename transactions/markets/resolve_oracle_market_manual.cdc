import "TrixyProtocol"

/// Manually resolves an oracle market after the oracle resolution deadline has passed
/// Only callable by admin as a fallback mechanism
/// @param marketId: The ID of the oracle market to resolve
/// @param outcome: true for YES outcome, false for NO outcome
transaction(marketId: UInt64, outcome: Bool) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let adminRef: &TrixyProtocol.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Get admin reference (required)
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can manually resolve oracle markets after deadline")
    }

    execute {
        // Manually resolve the oracle market
        self.marketCollectionRef.resolveOracleMarketManually(
            marketId: marketId,
            outcome: outcome,
            adminRef: self.adminRef
        )

        let outcomeStr = outcome ? "YES" : "NO"
        log("Oracle market ".concat(marketId.toString()).concat(" manually resolved by admin with outcome: ").concat(outcomeStr))
    }
}
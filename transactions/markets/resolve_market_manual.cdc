import "TrixyProtocol"

/// Manually resolves a prediction market
/// Can be called by market creator or admin
/// @param marketId: The ID of the market to resolve
/// @param outcome: true for YES outcome, false for NO outcome
transaction(marketId: UInt64, outcome: Bool) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let adminRef: &TrixyProtocol.Admin?

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Try to get admin reference (optional)
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
    }

    execute {
        // Resolve the market
        self.marketCollectionRef.resolveMarket(
            marketId: marketId,
            outcome: outcome,
            adminRef: self.adminRef
        )

        let outcomeStr = outcome ? "YES" : "NO"
        log("Market ".concat(marketId.toString()).concat(" resolved with outcome: ").concat(outcomeStr))
    }
}
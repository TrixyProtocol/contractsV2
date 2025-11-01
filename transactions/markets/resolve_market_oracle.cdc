import "TrixyProtocol"
import "FlowToken"
import "FungibleToken"

/// Resolves a prediction market using oracle data
/// Only callable by the market creator
/// @param marketId: The ID of the market to resolve
/// @param oracleFee: Amount to pay for oracle service
transaction(marketId: UInt64, oracleFee: UFix64) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let paymentVault: @FlowToken.Vault

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Get reference to Flow vault and withdraw oracle fee
        let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow Flow vault")
        
        self.paymentVault <- flowVault.withdraw(amount: oracleFee) as! @FlowToken.Vault
    }

    execute {
        // Resolve the market with oracle
        self.marketCollectionRef.resolveMarketWithOracle(
            marketId: marketId,
            payment: <-self.paymentVault
        )

        log("Market ".concat(marketId.toString()).concat(" resolved using oracle with fee ").concat(oracleFee.toString()).concat(" FLOW"))
    }
}
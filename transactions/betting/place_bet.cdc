import "TrixyProtocol"
import "FlowToken"
import "FungibleToken"

/// Places a bet on a prediction market
/// @param marketId: The ID of the market to bet on
/// @param isYes: true for YES bet, false for NO bet
/// @param amount: Amount of FLOW tokens to bet
transaction(marketId: UInt64, isYes: Bool, amount: UFix64) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let paymentVault: @FlowToken.Vault

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Get reference to Flow vault and withdraw payment
        let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow Flow vault")
        
        self.paymentVault <- flowVault.withdraw(amount: amount) as! @FlowToken.Vault
    }

    execute {
        // Place the bet
        self.marketCollectionRef.placeBet(
            marketId: marketId,
            isYes: isYes,
            payment: <-self.paymentVault
        )

        let betType = isYes ? "YES" : "NO"
        log("Placed ".concat(betType).concat(" bet of ").concat(amount.toString()).concat(" FLOW on market ").concat(marketId.toString()))
    }
}
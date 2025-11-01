import "TrixyProtocol"
import "FlowToken"
import "FungibleToken"

/// Claims winnings from a resolved prediction market
/// @param marketId: The ID of the market to claim winnings from
transaction(marketId: UInt64) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let receiverRef: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Get reference to Flow receiver
        self.receiverRef = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Flow token receiver")
    }

    execute {
        // Claim winnings
        let winningsVault <- self.marketCollectionRef.claimWinnings(marketId: marketId)
        let amount = winningsVault.balance

        // Deposit winnings to user's vault
        self.receiverRef.deposit(from: <-winningsVault)

        log("Claimed winnings of ".concat(amount.toString()).concat(" FLOW from market ").concat(marketId.toString()))
    }
}
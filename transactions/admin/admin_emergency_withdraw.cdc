import "TrixyProtocol"
import "FlowToken"
import "FungibleToken"

/// Emergency withdrawal from a market (admin only)
/// This cancels the market and withdraws all funds
/// @param marketId: The ID of the market to emergency withdraw from
transaction(marketId: UInt64) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let adminRef: &TrixyProtocol.Admin
    let receiverRef: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")

        // Get admin reference
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can perform emergency withdrawal")

        // Get reference to Flow receiver
        self.receiverRef = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Flow token receiver")
    }

    execute {
        // Emergency withdraw from market
        let withdrawnVault <- self.marketCollectionRef.emergencyWithdrawMarket(
            marketId: marketId,
            adminRef: self.adminRef
        )
        
        let amount = withdrawnVault.balance

        // Deposit withdrawn funds to admin's vault
        self.receiverRef.deposit(from: <-withdrawnVault)

        log("Emergency withdrawal of ".concat(amount.toString()).concat(" FLOW from market ").concat(marketId.toString()))
    }
}
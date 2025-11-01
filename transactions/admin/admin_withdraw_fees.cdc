import "TrixyProtocol"
import "FlowToken"
import "FungibleToken"

/// Withdraws collected protocol fees (admin only)
/// @param amount: Amount of fees to withdraw
transaction(amount: UFix64) {

    let adminRef: &TrixyProtocol.Admin
    let receiverRef: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        // Get admin reference
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can withdraw fees")

        // Get reference to Flow receiver
        self.receiverRef = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Flow token receiver")
    }

    execute {
        // Withdraw fees
        let feeVault <- self.adminRef.withdrawFees(amount: amount)

        // Deposit fees to admin's vault
        self.receiverRef.deposit(from: <-feeVault)

        log("Withdrew ".concat(amount.toString()).concat(" FLOW in protocol fees"))
    }
}
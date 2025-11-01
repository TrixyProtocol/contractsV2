import "TrixyProtocol"

/// Sets the protocol fee percentage (admin only)
/// @param newFee: New fee percentage (between 0.0 and 0.1 representing 0% to 10%)
transaction(newFee: UFix64) {

    let adminRef: &TrixyProtocol.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get admin reference
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can set fee percentage")
    }

    execute {
        // Set the new fee percentage
        self.adminRef.setFeePercent(newFee: newFee)

        let feePercentStr = (newFee * 100.0).toString().concat("%")
        log("Protocol fee percentage updated to: ".concat(feePercentStr))
    }
}
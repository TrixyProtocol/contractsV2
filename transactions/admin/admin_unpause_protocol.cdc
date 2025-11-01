import "TrixyProtocol"

/// Unpauses the Trixy protocol (admin only)
/// Allows normal protocol operations to resume
transaction() {

    let adminRef: &TrixyProtocol.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get admin reference
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can unpause the protocol")
    }

    execute {
        // Unpause the protocol
        self.adminRef.unpause()

        log("Protocol has been unpaused")
    }
}
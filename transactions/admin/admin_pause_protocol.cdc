import "TrixyProtocol"

/// Pauses the Trixy protocol (admin only)
/// Prevents new markets from being created and new bets from being placed
transaction() {

    let adminRef: &TrixyProtocol.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get admin reference
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required. Only admin can pause the protocol")
    }

    execute {
        // Pause the protocol
        self.adminRef.pause()

        log("Protocol has been paused")
    }
}
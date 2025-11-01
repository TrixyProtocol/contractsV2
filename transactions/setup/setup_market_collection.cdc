import "TrixyProtocol"

/// Sets up a new MarketCollection for the signer's account
/// This needs to be called once per account before creating or interacting with markets
transaction() {

    prepare(signer: auth(SaveValue, BorrowValue, IssueStorageCapabilityController, PublishCapability) &Account) {
        // Check if market collection already exists
        if signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath) == nil {
            // Create and save market collection
            signer.storage.save(<-TrixyProtocol.createMarketCollection() as @AnyResource, to: TrixyProtocol.MarketCollectionStoragePath)
            
            // Create and publish public capability
            let publicCapability = signer.capabilities.storage.issue<&{TrixyProtocol.MarketCollectionPublic}>(TrixyProtocol.MarketCollectionStoragePath)
            signer.capabilities.publish(publicCapability, at: TrixyProtocol.MarketCollectionPublicPath)
        }
    }

    execute {
        // Transaction completed successfully
    }
}

import "TrixyProtocol"
import "FlowTransactionSchedulerUtils"
import "FlowTransactionScheduler"
import "TrixyScheduledTransactionHandler"

/// Initialize scheduled transaction handlers and manager for Trixy Protocol
transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if market collection exists
        let marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(
            from: TrixyProtocol.MarketCollectionStoragePath
        )
        
        if marketCollectionRef == nil {
            panic("Market collection not found. Please create market collection first.")
        }
        
        // Create and save market resolution handler if not exists
        if signer.storage.borrow<&AnyResource>(from: /storage/TrixyMarketResolutionHandler) == nil {
            let resolutionHandler <- TrixyScheduledTransactionHandler.createMarketResolutionHandler()
            signer.storage.save(<-resolutionHandler, to: /storage/TrixyMarketResolutionHandler)
        }

        // Create entitled capability for the scheduler
        let resolutionHandlerCap = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(
                /storage/TrixyMarketResolutionHandler
            )

        // Create public capability
        let publicResolutionCap = signer.capabilities.storage
            .issue<&{FlowTransactionScheduler.TransactionHandler}>(/storage/TrixyMarketResolutionHandler)
        signer.capabilities.publish(publicResolutionCap, at: /public/TrixyMarketResolutionHandler)

        // Create yield harvest handler
        if signer.storage.borrow<&AnyResource>(from: /storage/TrixyYieldHarvestHandler) == nil {
            let yieldHandler <- TrixyScheduledTransactionHandler.createYieldHarvestHandler()
            signer.storage.save(<-yieldHandler, to: /storage/TrixyYieldHarvestHandler)
        }

        let yieldHandlerCap = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(
                /storage/TrixyYieldHarvestHandler
            )

        let publicYieldCap = signer.capabilities.storage
            .issue<&{FlowTransactionScheduler.TransactionHandler}>(/storage/TrixyYieldHarvestHandler)
        signer.capabilities.publish(publicYieldCap, at: /public/TrixyYieldHarvestHandler)

        // Create scheduler manager if not exists
        if !signer.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(
            from: TrixyProtocol.SchedulerManagerStoragePath
        ) {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            signer.storage.save(<-manager, to: TrixyProtocol.SchedulerManagerStoragePath)

            // Create public capability for the manager
            let managerRef = signer.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(
                TrixyProtocol.SchedulerManagerStoragePath
            )
            signer.capabilities.publish(managerRef, at: TrixyProtocol.SchedulerManagerPublicPath)
        }
        
        log("Scheduled transaction handlers and manager initialized successfully")
    }
}

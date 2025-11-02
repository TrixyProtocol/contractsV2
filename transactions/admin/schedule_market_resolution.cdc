import "TrixyProtocol"
import "TrixyTypes"
import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"

/// Schedule automatic resolution for an existing market
transaction(marketId: UInt64) {
    prepare(signer: auth(Storage, Capabilities, BorrowValue) &Account) {
        // Get market collection reference
        let marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(
            from: TrixyProtocol.MarketCollectionStoragePath
        ) ?? panic("Could not borrow market collection reference")
        
        // Get market info
        let marketInfo = marketCollectionRef.getMarketInfo(id: marketId)
            ?? panic("Market not found")
        
        // Get scheduler manager
        let manager = signer.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(
            from: TrixyProtocol.SchedulerManagerStoragePath
        ) ?? panic("Could not borrow scheduler manager")

        // Get handler capability
        let controllers = signer.capabilities.storage.getControllers(forPath: /storage/TrixyMarketResolutionHandler)
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }
        
        if handlerCap == nil {
            panic("Market resolution handler capability not found")
        }

        // Prepare market data
        let marketData: {String: AnyStruct} = {
            "marketId": marketId,
            "marketCollectionOwner": signer.address,
            "resolutionType": marketInfo.resolutionMethod == TrixyTypes.ResolutionMethod.Oracle ? "oracle" : "expire"
        }

        // Schedule for market end time + 5 minutes buffer
        let scheduledTime = marketInfo.endTime + 300.0

        // Estimate fees
        let est = FlowTransactionScheduler.estimate(
            data: marketData,
            timestamp: scheduledTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000
        )

        // Get fees from vault
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken vault")

        let fees <- vaultRef.withdraw(amount: est.flowFee ?? 0.001) as! @FlowToken.Vault

        // Schedule the transaction
        let scheduledId = manager.schedule(
            handlerCap: handlerCap!,
            data: marketData,
            timestamp: scheduledTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-fees
        )

        log("Scheduled automatic resolution for market ".concat(marketId.toString()).concat(" at ").concat(scheduledTime.toString()))
    }
}
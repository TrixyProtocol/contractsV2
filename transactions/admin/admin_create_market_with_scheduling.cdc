import "TrixyProtocol"
import "TrixyTypes"
import "FlowToken"
import "FungibleToken"

/// Create a new prediction market with optional automatic resolution scheduling
transaction(
    question: String,
    endTime: UFix64,
    yieldProtocol: String,
    resolutionMethod: UInt8, // 0 = Manual, 1 = Oracle
    scheduleAutomaticResolution: Bool,
    // Oracle parameters (optional)
    symbol: String?,
    targetPrice: UFix64?,
    comparisonType: UInt8?, // 0 = Greater, 1 = Less, 2 = Between
    targetPrice2: UFix64?,
    resolutionDeadline: UFix64?
) {
    prepare(signer: auth(Storage, Capabilities, BorrowValue) &Account) {
        // Get admin reference
        let adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(
            from: TrixyProtocol.AdminStoragePath
        ) ?? panic("Could not borrow admin reference")
        
        // Get market collection reference
        let marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(
            from: TrixyProtocol.MarketCollectionStoragePath
        ) ?? panic("Could not borrow market collection reference")
        
        // Convert resolution method
        let method = resolutionMethod == 0 
            ? TrixyTypes.ResolutionMethod.Manual 
            : TrixyTypes.ResolutionMethod.Oracle
        
        // Prepare oracle criteria if oracle resolution
        var oracleCriteria: TrixyTypes.OracleResolutionCriteria? = nil
        if method == TrixyTypes.ResolutionMethod.Oracle {
            assert(symbol != nil, message: "Symbol required for oracle resolution")
            assert(targetPrice != nil, message: "Target price required for oracle resolution")
            assert(comparisonType != nil, message: "Comparison type required for oracle resolution")
            assert(resolutionDeadline != nil, message: "Resolution deadline required for oracle resolution")
            
            let comparison = comparisonType! == 0 
                ? "ABOVE"
                : comparisonType! == 1 
                    ? "BELOW"
                    : "BETWEEN"
            
            oracleCriteria = TrixyTypes.OracleResolutionCriteria(
                symbol: symbol!,
                targetPrice: targetPrice!,
                comparisonType: comparison,
                targetPrice2: targetPrice2,
                resolutionDeadline: resolutionDeadline!
            )
        }
        
        // Create the market with scheduling option
        let marketId = marketCollectionRef.createMarket(
            question: question,
            endTime: endTime,
            yieldProtocol: yieldProtocol,
            resolutionMethod: method,
            oracleCriteria: oracleCriteria,
            adminRef: adminRef,
            scheduleAutomaticResolution: scheduleAutomaticResolution
        )
        
        log("Market created with ID: ".concat(marketId.toString()))
        if scheduleAutomaticResolution {
            log("Automatic resolution scheduled for market end time + 5 minutes")
        }
    }
}
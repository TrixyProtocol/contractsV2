import "TrixyProtocol"
import "TrixyTypes"

/// Creates a new prediction market
/// @param question: The question for the market
/// @param endTime: When the market ends (timestamp)
/// @param yieldProtocol: The yield protocol to use ("aave", "morpho", or "compound")
/// @param resolutionMethod: Manual (0) or Oracle (1)
/// @param symbol: Oracle symbol (optional, required for oracle markets)
/// @param targetPrice: Target price for oracle resolution (optional)
/// @param comparisonType: "ABOVE", "BELOW", or "BETWEEN" (optional)
/// @param targetPrice2: Second target price for "BETWEEN" comparisons (optional)
/// @param resolutionDeadline: Deadline for oracle resolution (optional)
transaction(
    question: String,
    endTime: UFix64,
    yieldProtocol: String,
    resolutionMethod: UInt8,
    symbol: String?,
    targetPrice: UFix64?,
    comparisonType: String?,
    targetPrice2: UFix64?,
    resolutionDeadline: UFix64?
) {

    let marketCollectionRef: &TrixyProtocol.MarketCollection
    let adminRef: &TrixyProtocol.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get reference to market collection
        self.marketCollectionRef = signer.storage.borrow<&TrixyProtocol.MarketCollection>(from: TrixyProtocol.MarketCollectionStoragePath)
            ?? panic("Market collection not found. Run setup_market_collection.cdc first")
        
        // Get admin reference (required for market creation)
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required to create markets")
    }

    execute {
        // Convert resolution method
        let resMethod = resolutionMethod == 0 ? TrixyTypes.ResolutionMethod.Manual : TrixyTypes.ResolutionMethod.Oracle
        
        // Create oracle criteria if needed
        var oracleCriteria: TrixyTypes.OracleResolutionCriteria? = nil
        if resMethod == TrixyTypes.ResolutionMethod.Oracle {
            assert(symbol != nil, message: "Symbol required for oracle markets")
            assert(targetPrice != nil, message: "Target price required for oracle markets")
            assert(comparisonType != nil, message: "Comparison type required for oracle markets")
            assert(resolutionDeadline != nil, message: "Resolution deadline required for oracle markets")
            
            oracleCriteria = TrixyTypes.OracleResolutionCriteria(
                symbol: symbol!,
                targetPrice: targetPrice!,
                comparisonType: comparisonType!,
                targetPrice2: targetPrice2,
                resolutionDeadline: resolutionDeadline!
            )
        }

        // Create the market
        let marketId = self.marketCollectionRef.createMarket(
            question: question,
            endTime: endTime,
            yieldProtocol: yieldProtocol,
            resolutionMethod: resMethod,
            oracleCriteria: oracleCriteria,
            adminRef: self.adminRef,
            scheduleAutomaticResolution: false
        )

        log("Market created with ID: ".concat(marketId.toString()))
    }
}
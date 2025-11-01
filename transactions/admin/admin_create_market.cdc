import "TrixyProtocol"
import "TrixyTypes"

/// Admin creates a market in a specified user's MarketCollection
/// @param userAddress: Address of the user whose MarketCollection will host the market
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
    userAddress: Address,
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

    let adminRef: &TrixyProtocol.Admin
    let userMarketCollection: &TrixyProtocol.MarketCollection

    prepare(signer: auth(BorrowValue) &Account) {
        // Get admin reference (required)
        self.adminRef = signer.storage.borrow<&TrixyProtocol.Admin>(from: TrixyProtocol.AdminStoragePath)
            ?? panic("Admin access required to create markets")

        // Get reference to user's market collection
        let userAccount = getAccount(userAddress)
        self.userMarketCollection = userAccount.capabilities.borrow<&TrixyProtocol.MarketCollection>(TrixyProtocol.MarketCollectionPublicPath)
            ?? panic("User does not have a MarketCollection or it's not properly set up")
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

        // Create the market as admin
        let marketId = self.userMarketCollection.createMarket(
            question: question,
            endTime: endTime,
            yieldProtocol: yieldProtocol,
            resolutionMethod: resMethod,
            oracleCriteria: oracleCriteria,
            adminRef: self.adminRef
        )

        log("Admin created market with ID: ".concat(marketId.toString()).concat(" in user ").concat(userAddress.toString()).concat("'s collection"))
    }
}
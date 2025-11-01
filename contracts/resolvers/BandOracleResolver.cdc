import "BandOracle"
import "FlowToken"
import "FungibleToken"

access(all) contract BandOracleResolver {

    /* --- STATE --- */

    access(all) let oracleFee: UFix64

    /* --- EVENTS --- */

    access(all) event OracleResolutionTriggered(
        marketId: UInt64,
        symbol: String,
        targetPrice: UFix64,
        actualPrice: UFix64,
        outcome: Bool
    )

    /* --- STRUCTS --- */

    access(all) struct ResolutionCriteria {
        access(all) let symbol: String
        access(all) let targetPrice: UFix64
        access(all) let comparisonType: String
        access(all) let targetPrice2: UFix64?

        init(
            symbol: String,
            targetPrice: UFix64,
            comparisonType: String,
            targetPrice2: UFix64?
        ) {
            pre {
                comparisonType == "ABOVE" || comparisonType == "BELOW" || comparisonType == "BETWEEN": 
                "Invalid comparison type"
            }
            self.symbol = symbol
            self.targetPrice = targetPrice
            self.comparisonType = comparisonType
            self.targetPrice2 = targetPrice2
        }
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun checkResolution(
        criteria: ResolutionCriteria,
        payment: @ {FungibleToken.Vault}
    ): {String: AnyStruct} {
        let oracleRef = BandOracle.getReferenceData(
            baseSymbol: criteria.symbol,
            quoteSymbol: "USD",
            payment: <- payment
        )

        let currentPrice = oracleRef.fixedPointRate
        let lastUpdate = UFix64(oracleRef.baseTimestamp)

        let currentTime = getCurrentBlock().timestamp
        let isRecent = (currentTime - lastUpdate) < 300.0

        if! isRecent {
            return {
                "canResolve": false,
            "outcome": false,
            "error": "Oracle data too old",
            "lastUpdate": lastUpdate
            }
        }

        var outcome = false

        switch criteria.comparisonType {
            case "ABOVE": 
                outcome = currentPrice >= criteria.targetPrice
            case "BELOW": 
                outcome = currentPrice <= criteria.targetPrice
            case "BETWEEN": 
                if let targetPrice2 = criteria.targetPrice2 {
                    outcome = currentPrice >= criteria.targetPrice
                    && currentPrice <= targetPrice2
                }
            default: 
                return {
                    "canResolve": false,
                    "outcome": false,
                    "error": "Invalid comparison type"
                }
        }

        return {
            "canResolve": true,
            "outcome": outcome,
            "currentPrice": currentPrice,
            "targetPrice": criteria.targetPrice,
            "symbol": criteria.symbol,
            "lastUpdate": lastUpdate
        }
    }

    access(all) fun resolveMarket(
        marketId: UInt64,
        criteria: ResolutionCriteria,
        payment: @ {FungibleToken.Vault}
    ): {String: AnyStruct} {
        let result = self.checkResolution(criteria: criteria, payment: <- payment)

        if result["canResolve"] as! Bool {
                emit OracleResolutionTriggered(
                marketId: marketId,
                symbol: criteria.symbol,
                targetPrice: criteria.targetPrice,
                actualPrice: result["currentPrice"] as! UFix64,
                outcome: result["outcome"] as! Bool
            )
        }

        return result
    }

    access(all) fun getCurrentPrice(
        symbol: String,
        payment: @ {FungibleToken.Vault}
    ): UFix64 {
        let oracleRef = BandOracle.getReferenceData(
            baseSymbol: symbol,
            quoteSymbol: "USD",
            payment: <- payment
        )
        return oracleRef.fixedPointRate
    }

    access(all) fun isOracleDataRecent(
        symbol: String,
        payment: @ {FungibleToken.Vault}
    ): Bool {
        let oracleRef = BandOracle.getReferenceData(
            baseSymbol: symbol,
            quoteSymbol: "USD",
            payment: <- payment
        )
        let currentTime = getCurrentBlock().timestamp
        let lastUpdate = UFix64(oracleRef.baseTimestamp)
        let timeDiff = currentTime - lastUpdate
        return timeDiff < 300.0
    }

    access(all) fun getSupportedSymbols(): [String] {
        return [
            "BTC",
            "ETH",
            "BNB",
            "MATIC",
            "AVAX",
            "SOL",
            "DOT",
            "LINK",
            "UNI",
            "AAVE"
        ]
    }

    access(all) fun createPriceTargetCriteria(
        symbol: String,
        targetPrice: UFix64
    ): ResolutionCriteria {
        return ResolutionCriteria(
            symbol: symbol,
            targetPrice: targetPrice,
            comparisonType: "ABOVE",
            targetPrice2: nil
        )
    }

    access(all) fun createMinPriceCriteria(
        symbol: String,
        minPrice: UFix64
    ): ResolutionCriteria {
        return ResolutionCriteria(
            symbol: symbol,
            targetPrice: minPrice,
            comparisonType: "ABOVE",
            targetPrice2: nil
        )
    }

    access(all) fun createPriceRangeCriteria(
        symbol: String,
        minPrice: UFix64,
        maxPrice: UFix64
    ): ResolutionCriteria {
        return ResolutionCriteria(
            symbol: symbol,
            targetPrice: minPrice,
            comparisonType: "BETWEEN",
            targetPrice2: maxPrice
        )
    }

    init() {
        self.oracleFee = 0.001
    }
}

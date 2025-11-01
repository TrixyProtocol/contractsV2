import "BandOracleConnectors"
import "DeFiActions"
import "FlowToken"
import "FungibleToken"
import "BandOracle"

access(all) contract BandOracleResolver {

    /* --- CONSTANTS --- */
    
    access(all) let MAX_DATA_AGE: UInt64
    access(all) let MIN_PAYMENT: UFix64
    access(all) let MAX_CALLS_PER_HOUR: UInt64

    /* --- STATE --- */

    access(all) var oracleFee: UFix64
    access(all) var paused: Bool
    access(self) var supportedAssets: {String: AssetConfig}
    access(self) var rateLimits: {Address: {UInt64: UInt64}}
    access(self) var admin: Address
    access(self) var feeSource: {DeFiActions.Source, DeFiActions.IdentifiableStruct}?

    /* --- EVENTS --- */

    access(all) event OracleResolutionTriggered(
        marketId: UInt64,
        symbol: String,
        targetPrice: UFix64,
        actualPrice: UFix64,
        outcome: Bool,
        timestamp: UFix64,
        caller: Address
    )

    access(all) event OracleResolutionFailed(
        marketId: UInt64,
        symbol: String,
        error: String,
        timestamp: UFix64,
        caller: Address
    )

    access(all) event PriceQueried(
        symbol: String,
        price: UFix64,
        timestamp: UFix64,
        dataTimestamp: UFix64,
        caller: Address
    )

    access(all) event AssetConfigUpdated(
        symbol: String,
        enabled: Bool,
        admin: Address
    )

    access(all) event ResolverPaused(admin: Address, timestamp: UFix64)
    access(all) event ResolverUnpaused(admin: Address, timestamp: UFix64)
    access(all) event FeeSourceUpdated(admin: Address, timestamp: UFix64)
    access(all) event RateLimitExceeded(caller: Address, timestamp: UFix64)

    /* --- STRUCTS --- */

    access(all) struct AssetConfig {
        access(all) let symbol: String
        access(all) let assetType: Type
        access(all) var enabled: Bool
        access(all) var minPrice: UFix64
        access(all) var maxPrice: UFix64
        access(all) let precision: UInt8

        init(symbol: String, assetType: Type, enabled: Bool, minPrice: UFix64, maxPrice: UFix64, precision: UInt8) {
            self.symbol = symbol
            self.assetType = assetType
            self.enabled = enabled
            self.minPrice = minPrice
            self.maxPrice = maxPrice
            self.precision = precision
        }

        access(all) fun setEnabled(_ enabled: Bool) {
            self.enabled = enabled
        }

        access(all) fun updatePriceLimits(minPrice: UFix64, maxPrice: UFix64) {
            pre {
                minPrice < maxPrice: "Min price must be less than max price"
                minPrice >= 0.0: "Min price must be non-negative"
            }
            self.minPrice = minPrice
            self.maxPrice = maxPrice
        }
    }

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
                    "Invalid comparison type. Must be ABOVE, BELOW, or BETWEEN"
                targetPrice > 0.0: "Target price must be positive"
                comparisonType != "BETWEEN" || targetPrice2 != nil: "BETWEEN comparison requires targetPrice2"
                targetPrice2 == nil || targetPrice2! > targetPrice: "targetPrice2 must be greater than targetPrice for BETWEEN comparison"
            }
            self.symbol = symbol
            self.targetPrice = targetPrice
            self.comparisonType = comparisonType
            self.targetPrice2 = targetPrice2
        }
    }

    access(all) struct OracleResult {
        access(all) let canResolve: Bool
        access(all) let outcome: Bool
        access(all) let currentPrice: UFix64?
        access(all) let dataTimestamp: UFix64?
        access(all) let error: String?
        access(all) let lastUpdate: UFix64

        init(canResolve: Bool, outcome: Bool, currentPrice: UFix64?, dataTimestamp: UFix64?, error: String?) {
            self.canResolve = canResolve
            self.outcome = outcome
            self.currentPrice = currentPrice
            self.dataTimestamp = dataTimestamp
            self.error = error
            self.lastUpdate = getCurrentBlock().timestamp
        }
    }

    /* --- ADMIN RESOURCE --- */

    access(all) resource Admin {
        
        access(all) fun pause() {
            BandOracleResolver.paused = true
            emit ResolverPaused(admin: BandOracleResolver.admin, timestamp: getCurrentBlock().timestamp)
        }

        access(all) fun unpause() {
            BandOracleResolver.paused = false
            emit ResolverUnpaused(admin: BandOracleResolver.admin, timestamp: getCurrentBlock().timestamp)
        }

        access(all) fun setFeeSource(feeSource: {DeFiActions.Source, DeFiActions.IdentifiableStruct}) {
            pre {
                feeSource.getSourceType() == Type<@FlowToken.Vault>(): "Fee source must provide FlowToken"
            }
            BandOracleResolver.feeSource = feeSource
            emit FeeSourceUpdated(admin: BandOracleResolver.admin, timestamp: getCurrentBlock().timestamp)
        }

        access(all) fun updateAssetConfig(symbol: String, enabled: Bool, minPrice: UFix64, maxPrice: UFix64) {
            if let config = BandOracleResolver.supportedAssets[symbol] {
                config.setEnabled(enabled)
                config.updatePriceLimits(minPrice: minPrice, maxPrice: maxPrice)
                BandOracleResolver.supportedAssets[symbol] = config
                emit AssetConfigUpdated(symbol: symbol, enabled: enabled, admin: BandOracleResolver.admin)
            }
        }

        access(all) fun addAsset(symbol: String, assetType: Type, enabled: Bool, minPrice: UFix64, maxPrice: UFix64, precision: UInt8) {
            pre {
                BandOracleConnectors.assetSymbols[assetType] != nil: "Asset type not supported by BandOracleConnectors"
                BandOracleConnectors.assetSymbols[assetType]! == symbol: "Symbol mismatch in BandOracleConnectors"
            }
            let config = AssetConfig(
                symbol: symbol,
                assetType: assetType,
                enabled: enabled,
                minPrice: minPrice,
                maxPrice: maxPrice,
                precision: precision
            )
            BandOracleResolver.supportedAssets[symbol] = config
            emit AssetConfigUpdated(symbol: symbol, enabled: enabled, admin: BandOracleResolver.admin)
        }

        access(all) fun setOracleFee(newFee: UFix64) {
            pre {
                newFee >= 0.0: "Fee must be non-negative"
                newFee <= 1.0: "Fee cannot exceed 1 FLOW"
            }
            BandOracleResolver.oracleFee = newFee
        }

        access(all) fun clearRateLimit(caller: Address) {
            BandOracleResolver.rateLimits[caller] = {}
        }
    }

    /* --- HELPER FUNCTIONS --- */
    
    access(self) fun validateSymbol(_ symbol: String): Bool {
        if let config = self.supportedAssets[symbol] {
            return config.enabled
        }
        return false
    }

    access(self) fun checkRateLimit(caller: Address): Bool {
        let currentHour = UInt64(getCurrentBlock().timestamp / 3600.0)
        
        if self.rateLimits[caller] == nil {
            self.rateLimits[caller] = {}
        }
        
        let currentCount = self.rateLimits[caller]![currentHour] ?? 0
        
        if currentCount >= self.MAX_CALLS_PER_HOUR {
            emit RateLimitExceeded(caller: caller, timestamp: getCurrentBlock().timestamp)
            return false
        }
        
        let callerRateLimits = self.rateLimits[caller]!
        callerRateLimits[currentHour] = currentCount + 1
        self.rateLimits[caller] = callerRateLimits
        return true
    }

    access(self) fun validatePrice(symbol: String, price: UFix64): Bool {
        if let config = self.supportedAssets[symbol] {
            return price >= config.minPrice && price <= config.maxPrice
        }
        return false
    }

    access(self) fun evaluateOutcome(criteria: ResolutionCriteria, currentPrice: UFix64): Bool {
        switch criteria.comparisonType {
            case "ABOVE":
                return currentPrice > criteria.targetPrice
            case "BELOW":
                return currentPrice < criteria.targetPrice
            case "BETWEEN":
                let upperBound = criteria.targetPrice2!
                return currentPrice >= criteria.targetPrice && currentPrice <= upperBound
            default:
                panic("Invalid comparison type: ".concat(criteria.comparisonType))
        }
    }

    access(self) fun createPriceOracle(): BandOracleConnectors.PriceOracle? {
        if let feeSource = self.feeSource {
            return BandOracleConnectors.PriceOracle(
                unitOfAccount: Type<@FlowToken.Vault>(),
                staleThreshold: self.MAX_DATA_AGE,
                feeSource: feeSource,
                uniqueID: nil
            )
        }
        return nil
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun checkResolution(
        criteria: ResolutionCriteria,
        payment: @ {FungibleToken.Vault},
        caller: Address
    ): {String: AnyStruct} {
        pre {
            !self.paused: "Oracle resolver is paused"
            payment.balance >= self.MIN_PAYMENT: "Payment insufficient"
        }
        
        if !self.checkRateLimit(caller: caller) {
            destroy payment
            let result = OracleResult(
                canResolve: false,
                outcome: false,
                currentPrice: nil,
                dataTimestamp: nil,
                error: "Rate limit exceeded. Maximum \(self.MAX_CALLS_PER_HOUR) calls per hour."
            )
            return self.oracleResultToDict(result)
        }
        
        if !self.validateSymbol(criteria.symbol) {
            destroy payment
            let result = OracleResult(
                canResolve: false,
                outcome: false,
                currentPrice: nil,
                dataTimestamp: nil,
                error: "Unsupported or disabled symbol: \(criteria.symbol)"
            )
            return self.oracleResultToDict(result)
        }
        
        if self.feeSource == nil {
            destroy payment
            let result = OracleResult(
                canResolve: false,
                outcome: false,
                currentPrice: nil,
                dataTimestamp: nil,
                error: "Oracle fee source not configured. Contact administrator."
            )
            return self.oracleResultToDict(result)
        }
        
        let totalPayment = payment.balance
        if totalPayment < self.oracleFee + BandOracle.getFee() {
            destroy payment
            let result = OracleResult(
                canResolve: false,
                outcome: false,
                currentPrice: nil,
                dataTimestamp: nil,
                error: "Insufficient payment. Required: \(self.oracleFee + BandOracle.getFee()), provided: \(totalPayment)"
            )
            return self.oracleResultToDict(result)
        }
        
        if self.oracleFee > 0.0 {
            let ourFee <- payment.withdraw(amount: self.oracleFee)
            destroy ourFee
        }
        destroy payment
        
        if let priceOracle = self.createPriceOracle() {
            let assetConfig = self.supportedAssets[criteria.symbol]!
            
            if let currentPrice = priceOracle.price(ofToken: assetConfig.assetType) {
                if !self.validatePrice(symbol: criteria.symbol, price: currentPrice) {
                    let result = OracleResult(
                        canResolve: false,
                        outcome: false,
                        currentPrice: currentPrice,
                        dataTimestamp: nil,
                        error: "Price ".concat(currentPrice.toString()).concat(" outside expected range [").concat(assetConfig.minPrice.toString()).concat(", ").concat(assetConfig.maxPrice.toString()).concat("]")
                    )
                    return self.oracleResultToDict(result)
                }
                
                let outcome = self.evaluateOutcome(criteria: criteria, currentPrice: currentPrice)
                
                let currentTimestamp = getCurrentBlock().timestamp
                let result = OracleResult(
                    canResolve: true,
                    outcome: outcome,
                    currentPrice: currentPrice,
                    dataTimestamp: currentTimestamp,
                    error: nil
                )
                
                emit PriceQueried(
                    symbol: criteria.symbol,
                    price: currentPrice,
                    timestamp: currentTimestamp,
                    dataTimestamp: currentTimestamp,
                    caller: caller
                )
                
                return self.oracleResultToDict(result)
            } else {
                let result = OracleResult(
                    canResolve: false,
                    outcome: false,
                    currentPrice: nil,
                    dataTimestamp: nil,
                    error: "Failed to retrieve price data for \(criteria.symbol)"
                )
                return self.oracleResultToDict(result)
            }
        } else {
            let result = OracleResult(
                canResolve: false,
                outcome: false,
                currentPrice: nil,
                dataTimestamp: nil,
                error: "Could not create price oracle. Fee source not properly configured."
            )
            return self.oracleResultToDict(result)
        }
    }

    access(all) fun resolveMarket(
        marketId: UInt64,
        criteria: ResolutionCriteria,
        payment: @ {FungibleToken.Vault},
        caller: Address
    ): {String: AnyStruct} {
        let result = self.checkResolution(criteria: criteria, payment: <- payment, caller: caller)

        if result["canResolve"] as! Bool {
            emit OracleResolutionTriggered(
                marketId: marketId,
                symbol: criteria.symbol,
                targetPrice: criteria.targetPrice,
                actualPrice: result["currentPrice"] as! UFix64,
                outcome: result["outcome"] as! Bool,
                timestamp: getCurrentBlock().timestamp,
                caller: caller
            )
        } else {
            emit OracleResolutionFailed(
                marketId: marketId,
                symbol: criteria.symbol,
                error: result["error"] as? String ?? "Unknown error",
                timestamp: getCurrentBlock().timestamp,
                caller: caller
            )
        }

        return result
    }

    access(all) fun getCurrentPrice(
        symbol: String,
        payment: @ {FungibleToken.Vault},
        caller: Address
    ): UFix64 {
        pre {
            !self.paused: "Oracle resolver is paused"
            payment.balance >= self.MIN_PAYMENT: "Payment insufficient"
        }
        
        assert(self.checkRateLimit(caller: caller), message: "Rate limit exceeded. Maximum ".concat(self.MAX_CALLS_PER_HOUR.toString()).concat(" calls per hour."))
        
        assert(self.validateSymbol(symbol), message: "Unsupported or disabled symbol: ".concat(symbol))
        
        assert(payment.balance >= self.oracleFee, message: "Insufficient payment for oracle fee")
        
        if self.oracleFee > 0.0 {
            let ourFee <- payment.withdraw(amount: self.oracleFee)
            destroy ourFee
        }
        destroy payment
        
        if let priceOracle = self.createPriceOracle() {
            let assetConfig = self.supportedAssets[symbol]!
            if let price = priceOracle.price(ofToken: assetConfig.assetType) {
                assert(self.validatePrice(symbol: symbol, price: price), message: "Price ".concat(price.toString()).concat(" outside expected range [").concat(assetConfig.minPrice.toString()).concat(", ").concat(assetConfig.maxPrice.toString()).concat("]"))
                
                emit PriceQueried(
                    symbol: symbol,
                    price: price,
                    timestamp: getCurrentBlock().timestamp,
                    dataTimestamp: getCurrentBlock().timestamp,
                    caller: caller
                )
                
                return price
            } else {
                panic("Failed to retrieve price data for ".concat(symbol))
            }
        } else {
            panic("Could not create price oracle. Fee source not properly configured.")
        }
    }

    access(all) fun isOracleDataRecent(
        symbol: String,
        payment: @ {FungibleToken.Vault}
    ): Bool {
        let isSupported = self.validateSymbol(symbol)
        destroy payment
        return isSupported && !self.paused && self.feeSource != nil
    }

    access(all) fun getSupportedSymbols(): [String] {
        let symbols: [String] = []
        for symbol in self.supportedAssets.keys {
            if self.supportedAssets[symbol]!.enabled {
                symbols.append(symbol)
            }
        }
        return symbols
    }

    access(all) fun getAssetConfig(symbol: String): AssetConfig? {
        return self.supportedAssets[symbol]
    }

    access(all) fun getOracleFee(): UFix64 {
        return self.oracleFee + BandOracle.getFee()
    }

    access(all) fun isPaused(): Bool {
        return self.paused
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

    /* --- UTILITY FUNCTIONS --- */
    
    access(self) fun oracleResultToDict(_ result: OracleResult): {String: AnyStruct} {
        let dict: {String: AnyStruct} = {
            "canResolve": result.canResolve,
            "outcome": result.outcome,
            "lastUpdate": result.lastUpdate
        }
        
        if let price = result.currentPrice {
            dict["currentPrice"] = price
        }
        
        if let dataTimestamp = result.dataTimestamp {
            dict["dataTimestamp"] = dataTimestamp
        }
        
        if let error = result.error {
            dict["error"] = error
        }
        
        return dict
    }

    access(all) fun getAdminStoragePath(): StoragePath {
        return /storage/BandOracleResolverAdmin
    }

    init() {
        self.MAX_DATA_AGE = 300
        self.MIN_PAYMENT = 0.001
        self.MAX_CALLS_PER_HOUR = 100
        
        self.oracleFee = 0.001
        self.paused = false
        self.admin = self.account.address
        self.rateLimits = {}
        self.feeSource = nil
        
        self.supportedAssets = {
            "FLOW": AssetConfig(
                symbol: "FLOW",
                assetType: Type<@FlowToken.Vault>(),
                enabled: true,
                minPrice: 0.01,
                maxPrice: 1000.0,
                precision: 8
            )
        }
        
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.getAdminStoragePath())
    }
}

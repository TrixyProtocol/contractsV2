import "FlowToken"
import "FungibleToken"
import "PredictionMarket"
import "TrixyEvents"
import "TrixyTypes"

access(all) contract TrixyProtocol {

    /* --- PATHS --- */

    access(all) let AdminStoragePath: StoragePath
    access(all) let MarketCollectionStoragePath: StoragePath
    access(all) let MarketCollectionPublicPath: PublicPath

    /* --- STATE --- */

    access(self) var nextMarketId: UInt64
    access(self) var protocolFeePercent: UFix64
    access(self) var paused: Bool
    access(self) let feeVault: @FlowToken.Vault
    access(self) let protocolAdmin: Address

    /* --- EVENTS --- */

    access(all) event ProtocolPaused(admin: Address)
    access(all) event ProtocolUnpaused(admin: Address)
    access(all) event FeePercentUpdated(oldFee: UFix64, newFee: UFix64, admin: Address)
    access(all) event FeesWithdrawn(amount: UFix64, recipient: Address)
    access(all) event MarketCollectionCreated(owner: Address)

    /* --- INTERFACES --- */

    access(all) resource interface MarketCollectionPublic {
        access(all) fun getMarketIds(): [UInt64]
        access(all) fun borrowMarket(id: UInt64): &PredictionMarket.MarketResource?
        access(all) fun getMarketInfo(id: UInt64): TrixyTypes.PredictionMarketInfo?
    }

    /* --- RESOURCES --- */

    access(all) resource Admin {

        access(all) fun pause() {
            TrixyProtocol.paused = true
            emit ProtocolPaused(admin: self.owner! .address)
        }

        access(all) fun unpause() {
            TrixyProtocol.paused = false
            emit ProtocolUnpaused(admin: self.owner! .address)
        }

        access(all) fun setFeePercent(newFee: UFix64) {
            pre {
                newFee <= 0.1: "Fee cannot exceed 10%"
                newFee >= 0.0: "Fee must be non - negative"
            }
            let oldFee = TrixyProtocol.protocolFeePercent
            TrixyProtocol.protocolFeePercent = newFee
            emit FeePercentUpdated(oldFee: oldFee, newFee: newFee, admin: self.owner! .address)
        }

        access(all) fun withdrawFees(amount: UFix64): @FlowToken.Vault {
            pre {
                amount <= TrixyProtocol.feeVault.balance: "Insufficient fee balance"
            }
            emit FeesWithdrawn(amount: amount, recipient: self.owner! .address)
            return <- TrixyProtocol.feeVault.withdraw(amount: amount) as! @FlowToken.Vault
        }

        access(all) fun getTotalFees(): UFix64 {
            return TrixyProtocol.feeVault.balance
        }
    }

    access(all) resource MarketCollection: MarketCollectionPublic {
        access(self) let markets: @ {UInt64: PredictionMarket.MarketResource}

        init() {
            self.markets <- {}
        }

        access(all) fun createMarket(
            question: String,
            endTime: UFix64,
            yieldProtocol: String,
            resolutionMethod: TrixyTypes.ResolutionMethod,
            oracleCriteria: TrixyTypes.OracleResolutionCriteria?
        ): UInt64 {
            pre {
                !TrixyProtocol.paused: "Protocol is paused"
                endTime > getCurrentBlock().timestamp: "End time must be in future"
                endTime < getCurrentBlock().timestamp + 31536000.0: "Market duration max 1 year"
                resolutionMethod == TrixyTypes.ResolutionMethod.Manual || oracleCriteria != nil: "Oracle criteria required for oracle resolution"
            }

            let marketId = TrixyProtocol.nextMarketId
            TrixyProtocol.nextMarketId = TrixyProtocol.nextMarketId + 1

            let market <- PredictionMarket.createMarket(
                id: marketId,
                question: question,
                endTime: endTime,
                creator: self.owner! .address,
                yieldProtocol: yieldProtocol,
                protocolFee: TrixyProtocol.protocolFeePercent,
                resolutionMethod: resolutionMethod,
                oracleCriteria: oracleCriteria
            )

            self.markets[marketId] <-! market

            return marketId
        }

        access(all) fun placeBet(
            marketId: UInt64,
            isYes: Bool,
            payment: @FlowToken.Vault
        ) {
            pre {
                !TrixyProtocol.paused: "Protocol is paused"
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            let amount = payment.balance
            let feeAmount = amount * TrixyProtocol.protocolFeePercent

            if feeAmount > 0.0 {
                let fee <- payment.withdraw(amount: feeAmount) as! @FlowToken.Vault
                TrixyProtocol.feeVault.deposit(from: <- fee)
            }

            marketRef! .placeBet(
                user: self.owner! .address,
                isYes: isYes,
                payment: <- payment,
                protocolFee: 0.0
            )
        }

        access(all) fun resolveMarket(marketId: UInt64, outcome: Bool, adminRef: &Admin?) {
            pre {
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            let market = marketRef!

            assert(
                market.creator == self.owner! .address || adminRef!= nil,
                message: "Not authorized to resolve market"
            )

            market.resolveMarket(outcome: outcome)
        }

        access(all) fun resolveMarketWithOracle(marketId: UInt64, payment: @FlowToken.Vault) {
            pre {
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            let market = marketRef!
            let caller = self.owner!.address

            // Only the market creator can trigger oracle resolution
            assert(
                market.creator == caller,
                message: "Only market creator can trigger oracle resolution"
            )

            market.resolveMarketWithOracle(payment: <- payment, caller: caller)
        }

        access(all) fun resolveOracleMarketManually(marketId: UInt64, outcome: Bool, adminRef: &Admin) {
            pre {
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            let market = marketRef!

            // Admin reference confirms authorization - pass as optional
            market.resolveOracleMarketManually(outcome: outcome, adminRef: adminRef)
        }

        access(all) fun claimWinnings(marketId: UInt64): @FlowToken.Vault {
            pre {
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            return <- marketRef! .claimWinnings(user: self.owner! .address)
        }

        access(all) fun getMarketIds(): [UInt64] {
            return self.markets.keys
        }

        access(all) fun borrowMarket(id: UInt64): &PredictionMarket.MarketResource? {
            return &self.markets[id]
        }

        access(all) fun getMarketInfo(id: UInt64): TrixyTypes.PredictionMarketInfo? {
            if let marketRef = &self.markets[id] as &PredictionMarket.MarketResource? {
                return marketRef.getInfo()
            }
            return nil
        }

        access(all) fun emergencyWithdrawMarket(marketId: UInt64, adminRef: &Admin): @FlowToken.Vault {
            pre {
                self.markets[marketId]!= nil: "Market not found"
            }

            let marketRef = &self.markets[marketId] as &PredictionMarket.MarketResource?
            return <- marketRef!.emergencyWithdraw()
        }
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun createMarketCollection(): @MarketCollection {
        emit MarketCollectionCreated(owner: self.account.address)
        return <- create MarketCollection()
    }

    access(all) fun isPaused(): Bool {
        return self.paused
    }

    access(all) fun getFeePercent(): UFix64 {
        return self.protocolFeePercent
    }

    access(all) fun getAdminAddress(): Address {
        return self.protocolAdmin
    }

    init() {
        self.AdminStoragePath = /storage/TrixyAdmin
        self.MarketCollectionStoragePath = /storage/TrixyMarketCollection
        self.MarketCollectionPublicPath = /public/TrixyMarketCollection

        self.nextMarketId = 0
        self.protocolFeePercent = 0.02
        self.paused = false
        self.feeVault <- FlowToken.createEmptyVault(vaultType: Type < @FlowToken.Vault > ())
        self.protocolAdmin = self.account.address

        let admin <- create Admin()
        self.account.storage.save( <-admin, to: self.AdminStoragePath)
    }
}

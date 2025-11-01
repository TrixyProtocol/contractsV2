import "FlowToken"
import "FungibleToken"
import "TrixyEvents"
import "TrixyTypes"
import "IncrementAdapter"
import "BandOracleResolver"

access(all) contract PredictionMarket {

    /* --- CONSTANTS --- */

    access(all) resource MarketResource {
        access(all) let id: UInt64
        access(all) let question: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let creator: Address
        access(all) let yieldProtocol: String

        access(all) var status: TrixyTypes.MarketStatus
        access(all) var outcome: Bool?
        access(all) let resolutionMethod: TrixyTypes.ResolutionMethod
        access(all) let oracleCriteria: TrixyTypes.OracleResolutionCriteria?

        access(self) let vault: @FlowToken.Vault

        access(all) var totalYesShares: UFix64
        access(all) var totalNoShares: UFix64
        access(all) var totalYieldEarned: UFix64

        access(self) let userPositions: {Address: TrixyTypes.BinaryPosition}

        access(self) let yieldVault: @FlowToken.Vault
        access(self) var stakingPositionId: String?
        access(self) let incrementAdapter: &IncrementAdapter

        init(
            id: UInt64,
            question: String,
            endTime: UFix64,
            creator: Address,
            yieldProtocol: String,
            protocolFee: UFix64,
            resolutionMethod: TrixyTypes.ResolutionMethod,
            oracleCriteria: TrixyTypes.OracleResolutionCriteria?
        ) {
            pre {
                endTime > getCurrentBlock().timestamp: "End time must be in future"
                yieldProtocol == "aave" || yieldProtocol == "morpho" || yieldProtocol == "compound": "Invalid yield protocol"
                resolutionMethod == TrixyTypes.ResolutionMethod.Manual || oracleCriteria != nil: "Oracle criteria required for oracle resolution"
            }

            self.id = id
            self.question = question
            self.startTime = getCurrentBlock().timestamp
            self.endTime = endTime
            self.creator = creator
            self.yieldProtocol = yieldProtocol
            self.status = TrixyTypes.MarketStatus.Active
            self.outcome = nil
            self.resolutionMethod = resolutionMethod
            self.oracleCriteria = oracleCriteria

            self.vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            self.yieldVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            self.stakingPositionId = nil
            self.incrementAdapter = PredictionMarket.getIncrementAdapterRef()

            self.totalYesShares = 0.0
            self.totalNoShares = 0.0
            self.totalYieldEarned = 0.0
            self.userPositions = {}
        }

        access(all) fun placeBet(
            user: Address,
            isYes: Bool,
            payment: @FlowToken.Vault,
            protocolFee: UFix64
        ) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market not active"
                getCurrentBlock().timestamp < self.endTime: "Market ended"
                payment.balance > 0.0: "Amount must be > 0"
            }

            let amount = payment.balance
            let feeAmount = amount * protocolFee
            let netAmount = amount - feeAmount

            if feeAmount > 0.0 {
                let fee <- payment.withdraw(amount: feeAmount) as! @FlowToken.Vault
                destroy fee
            }

            self.vault.deposit(from: <- payment)

            if let existingPosition = self.userPositions[user] {
                let updatedPosition = TrixyTypes.BinaryPosition(
                    yesShares: isYes ? existingPosition.yesShares + netAmount: existingPosition.yesShares,
                    noShares: isYes ? existingPosition.noShares: existingPosition.noShares + netAmount
                )
                self.userPositions[user] = updatedPosition
            } else {
                let newPosition = TrixyTypes.BinaryPosition(
                    yesShares: isYes ? netAmount: 0.0,
                    noShares: isYes ? 0.0: netAmount
                )
                self.userPositions[user] = newPosition
            }

            if isYes {
                self.totalYesShares = self.totalYesShares + netAmount
            } else {
                self.totalNoShares = self.totalNoShares + netAmount
            }

            self.depositToYieldProtocol(amount: netAmount)

            TrixyEvents.emitBetPlaced(
                marketId: self.id,
                user: user,
                selectedOption: isYes ? "YES": "NO",
                amount: netAmount
            )
        }

        access(self) fun depositToYieldProtocol(amount: UFix64) {
            let funds <- self.vault.withdraw(amount: amount) as! @FlowToken.Vault

            if self.stakingPositionId == nil {
                self.stakingPositionId = self.incrementAdapter.stake(vault: <- funds)
            } else {
                let newPositionId = self.incrementAdapter.stake(vault: <- funds)
                self.stakingPositionId = newPositionId
            }

            TrixyEvents.emitYieldDeposited(
                marketId: self.id,
                protocol: "increment",
                amount: amount
            )
        }

        access(all) fun resolveMarket(outcome: Bool) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market already resolved"
                getCurrentBlock().timestamp >= self.endTime: "Market not ended"
                self.resolutionMethod == TrixyTypes.ResolutionMethod.Manual: "Use resolveMarketWithOracle for oracle markets"
            }

            self.outcome = outcome
            self.status = TrixyTypes.MarketStatus.Resolved

            self.withdrawAllFromYieldProtocol()

            let protocolAPYs: {String: UFix64} = {}
            protocolAPYs["YES"] = 0.0
            protocolAPYs["NO"] = 0.0

            TrixyEvents.emitMarketResolved(
                marketId: self.id,
                winningOption: outcome ? "YES": "NO",
                apys: protocolAPYs
            )
        }

        access(all) fun resolveMarketWithOracle(payment: @FlowToken.Vault, caller: Address) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market already resolved"
                getCurrentBlock().timestamp >= self.endTime: "Market not ended"
                self.resolutionMethod == TrixyTypes.ResolutionMethod.Oracle: "Market does not use oracle resolution"
                self.oracleCriteria != nil: "No oracle criteria set"
            }

            let criteria = self.oracleCriteria!
            
            assert(
                getCurrentBlock().timestamp <= criteria.resolutionDeadline,
                message: "Oracle resolution deadline has passed. Use manual resolution fallback."
            )
            
            let resolverCriteria = BandOracleResolver.ResolutionCriteria(
                symbol: criteria.symbol,
                targetPrice: criteria.targetPrice,
                comparisonType: criteria.comparisonType,
                targetPrice2: criteria.targetPrice2
            )

            let oracleResolver = PredictionMarket.getBandOracleResolverRef()
            let result = oracleResolver.resolveMarket(
                marketId: self.id,
                criteria: resolverCriteria,
                payment: <- payment,
                caller: caller
            )

            if result["canResolve"] as! Bool {
                let outcome = result["outcome"] as! Bool
                self.outcome = outcome
                self.status = TrixyTypes.MarketStatus.Resolved

                self.withdrawAllFromYieldProtocol()

                let protocolAPYs: {String: UFix64} = {}
                protocolAPYs["YES"] = 0.0
                protocolAPYs["NO"] = 0.0

                TrixyEvents.emitMarketResolved(
                    marketId: self.id,
                    winningOption: outcome ? "YES": "NO",
                    apys: protocolAPYs
                )
            } else {
                panic("Oracle resolution failed: ".concat(result["error"] as? String ?? "Unknown error"))
            }
        }

        access(all) fun resolveOracleMarketManually(outcome: Bool, adminRef: AnyStruct?) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market already resolved"
                getCurrentBlock().timestamp >= self.endTime: "Market not ended"
                self.resolutionMethod == TrixyTypes.ResolutionMethod.Oracle: "Market does not use oracle resolution"
                self.oracleCriteria != nil: "No oracle criteria set"
                getCurrentBlock().timestamp > self.oracleCriteria!.resolutionDeadline: "Oracle resolution deadline has not passed"
                adminRef != nil: "Only admin can manually resolve oracle markets after deadline"
            }

            self.outcome = outcome
            self.status = TrixyTypes.MarketStatus.Resolved

            self.withdrawAllFromYieldProtocol()

            let protocolAPYs: {String: UFix64} = {}
            protocolAPYs["YES"] = 0.0
            protocolAPYs["NO"] = 0.0

            TrixyEvents.emitMarketResolved(
                marketId: self.id,
                winningOption: outcome ? "YES": "NO",
                apys: protocolAPYs
            )
        }

        access(self) fun withdrawAllFromYieldProtocol() {
            if let positionId = self.stakingPositionId {
                let originalStake = self.totalYesShares + self.totalNoShares
                
                let stakedBalance = self.incrementAdapter.getBalance(positionId: positionId)
                let availableRewards = self.incrementAdapter.getAvailableRewards(positionId: positionId)
                
                if availableRewards > 0.0 {
                    let rewards <- self.incrementAdapter.claimRewards(positionId: positionId)
                    self.yieldVault.deposit(from: <- rewards)
                }
                
                if stakedBalance > 0.0 {
                    let unstaked <- self.incrementAdapter.unstake(amount: stakedBalance, positionId: positionId)
                    self.yieldVault.deposit(from: <- unstaked)
                }
                
                let totalWithdrawn = self.yieldVault.balance
                let yieldEarned = totalWithdrawn > originalStake ? totalWithdrawn - originalStake : 0.0
                
                if yieldEarned > 0.0 {
                    self.totalYieldEarned = yieldEarned
                }
                
                if self.yieldVault.balance > 0.0 {
                    let withdrawn <- self.yieldVault.withdraw(amount: self.yieldVault.balance)
                    self.vault.deposit(from: <- withdrawn)
                }

                TrixyEvents.emitYieldWithdrawn(
                    marketId: self.id,
                    protocol: "increment",
                    amount: totalWithdrawn,
                    yieldEarned: yieldEarned
                )
                
                self.stakingPositionId = nil
            }
        }

        access(all) fun claimWinnings(user: Address): @FlowToken.Vault {
            pre {
                self.status == TrixyTypes.MarketStatus.Resolved: "Market not resolved"
                self.userPositions[user]!= nil: "No position found"
                !self.userPositions[user]! .claimed: "Already claimed"
            }

            let position = self.userPositions[user]!
            let payout = self.calculatePayout(position: position)

            var updatedPosition = position
            updatedPosition.setClaimed()
            self.userPositions[user] = updatedPosition

            TrixyEvents.emitWinningsClaimed(marketId: self.id, user: user, payout: payout)

            return <- self.vault.withdraw(amount: payout) as! @FlowToken.Vault
        }

        access(self) fun calculatePayout(position: TrixyTypes.BinaryPosition): UFix64 {
            let winningShares = self.outcome! ? position.yesShares: position.noShares
            let losingShares = self.outcome! ? position.noShares: position.yesShares

            let totalWinningShares = self.outcome! ? self.totalYesShares: self.totalNoShares
            let totalLosingShares = self.outcome! ? self.totalNoShares: self.totalYesShares

            var payout = 0.0

            if winningShares > 0.0 && totalWinningShares > 0.0 {
                let userShareOfWinners = winningShares / totalWinningShares

                payout = payout + winningShares

                if totalLosingShares > 0.0 {
                    payout = payout + (totalLosingShares * userShareOfWinners)
                }

                if self.totalYieldEarned > 0.0 {
                    payout = payout + (self.totalYieldEarned * userShareOfWinners)
                }
            }

            if losingShares > 0.0 && totalLosingShares > 0.0 {
                let userShareOfLosers = losingShares / totalLosingShares

                if self.totalYieldEarned > 0.0 {
                    payout = payout + (self.totalYieldEarned * userShareOfLosers)
                }
            }

            return payout
        }

        access(all) fun emergencyWithdraw(): @FlowToken.Vault {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Can only emergency withdraw from active markets"
            }

            self.status = TrixyTypes.MarketStatus.Cancelled

            let yieldBalance = self.yieldVault.balance
            if yieldBalance > 0.0 {
                let yieldFunds <- self.yieldVault.withdraw(amount: yieldBalance)
                self.vault.deposit(from: <- yieldFunds)
            }

            let totalBalance = self.vault.balance
            return <- self.vault.withdraw(amount: totalBalance) as! @FlowToken.Vault
        }

        access(all) fun getInfo(): TrixyTypes.PredictionMarketInfo {
            return TrixyTypes.PredictionMarketInfo(
                id: self.id,
                question: self.question,
                startTime: self.startTime,
                endTime: self.endTime,
                yieldProtocol: self.yieldProtocol,
                status: self.status,
                outcome: self.outcome,
                totalYesShares: self.totalYesShares,
                totalNoShares: self.totalNoShares,
                totalYieldEarned: self.totalYieldEarned,
                totalPool: self.vault.balance + self.yieldVault.balance,
                resolutionMethod: self.resolutionMethod,
                oracleCriteria: self.oracleCriteria
            )
        }
    }

    access(all) fun createMarket(
        id: UInt64,
        question: String,
        endTime: UFix64,
        creator: Address,
        yieldProtocol: String,
        protocolFee: UFix64,
        resolutionMethod: TrixyTypes.ResolutionMethod,
        oracleCriteria: TrixyTypes.OracleResolutionCriteria?
    ): @MarketResource {
        return <- create MarketResource(
            id: id,
            question: question,
            endTime: endTime,
            creator: creator,
            yieldProtocol: yieldProtocol,
            protocolFee: protocolFee,
            resolutionMethod: resolutionMethod,
            oracleCriteria: oracleCriteria
        )
    }

    access(all) fun getIncrementAdapterRef(): &IncrementAdapter {
        return getAccount(Type<IncrementAdapter>().address!)
            .contracts.borrow<&IncrementAdapter>(name: "IncrementAdapter")
            ?? panic("IncrementAdapter contract not found")
    }

    access(all) fun getBandOracleResolverRef(): &BandOracleResolver {
        return getAccount(Type<BandOracleResolver>().address!)
            .contracts.borrow<&BandOracleResolver>(name: "BandOracleResolver")
            ?? panic("BandOracleResolver contract not found")
    }
}

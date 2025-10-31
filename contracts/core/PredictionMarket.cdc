

import "FlowToken"
import "FungibleToken"
import "TrixyEvents"
import "TrixyTypes"

access(all) contract PredictionMarket {

    access(all) resource MarketResource {
            access(all) let id: UInt64
        access(all) let question: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let creator: Address
        access(all) let yieldProtocol: String

        access(all) var status: TrixyTypes.MarketStatus
        access(all) var outcome: Bool?

        access(self) let vault: @FlowToken.Vault

        access(all) var totalYesShares: UFix64
        access(all) var totalNoShares: UFix64
        access(all) var totalYieldEarned: UFix64

        access(self) let userPositions: {Address: TrixyTypes.BinaryPosition}

        access(self) let yieldVault: @FlowToken.Vault

        init(
            id: UInt64,
            question: String,
            endTime: UFix64,
            creator: Address,
            yieldProtocol: String,
            protocolFee: UFix64
        ) {
                pre {
                    endTime > getCurrentBlock().timestamp: "End time must be in future"
                yieldProtocol == "aave" || yieldProtocol == "morpho" || yieldProtocol == "compound": "Invalid yield protocol"
                }

            self.id = id
            self.question = question
            self.startTime = getCurrentBlock().timestamp
            self.endTime = endTime
            self.creator = creator
            self.yieldProtocol = yieldProtocol
            self.status = TrixyTypes.MarketStatus.Active
            self.outcome = nil

            self.vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            self.yieldVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())

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

            self.yieldVault.deposit(from: <- funds)

            TrixyEvents.emitYieldDeposited(
                marketId: self.id,
                protocol: self.yieldProtocol,
                amount: amount
            )
            }

        access(all) fun resolveMarket(outcome: Bool) {
                pre {
                    self.status == TrixyTypes.MarketStatus.Active: "Market already resolved"
                getCurrentBlock().timestamp >= self.endTime: "Market not ended"
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
                let balance = self.yieldVault.balance

            if balance > 0.0 {

                let originalStake = self.totalYesShares + self.totalNoShares
                let yieldEarned = balance > originalStake ? balance - originalStake: 0.0

                if yieldEarned > 0.0 {
                        self.totalYieldEarned = yieldEarned
                    }

                let withdrawn <- self.yieldVault.withdraw(amount: balance)
                self.vault.deposit(from: <- withdrawn)

                TrixyEvents.emitYieldWithdrawn(
                    marketId: self.id,
                    protocol: self.yieldProtocol,
                    amount: balance,
                    yieldEarned: yieldEarned
                )
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
                totalPool: self.vault.balance + self.yieldVault.balance
            )
            }
        }

    access(all) fun createMarket(
        id: UInt64,
        question: String,
        endTime: UFix64,
        creator: Address,
        yieldProtocol: String,
        protocolFee: UFix64
    ): @MarketResource {
            return <- create MarketResource(
            id: id,
            question: question,
            endTime: endTime,
            creator: creator,
            yieldProtocol: yieldProtocol,
            protocolFee: protocolFee
        )
        }
    }

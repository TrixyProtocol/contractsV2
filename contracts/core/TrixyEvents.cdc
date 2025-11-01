access(all) contract TrixyEvents {

    /* --- EVENTS --- */

    access(all) event ContractInitialized()

    access(all) event MarketCreated(
        marketId: UInt64,
        question: String,
        endTime: UFix64,
        options: [String],
        yieldProtocol: String,
        creator: Address
    )

    access(all) event BetPlaced(
        marketId: UInt64,
        user: Address,
        selectedOption: String,
        amount: UFix64,
        timestamp: UFix64
    )

    access(all) event MarketResolved(
        marketId: UInt64,
        winningOption: String,
        finalAPYs: {String: UFix64},
        resolvedAt: UFix64
    )

    access(all) event WinningsClaimed(
        marketId: UInt64,
        user: Address,
        payout: UFix64,
        timestamp: UFix64
    )

    access(all) event YieldDeposited(
        marketId: UInt64,
        protocol: String,
        amount: UFix64,
        timestamp: UFix64
    )

    access(all) event YieldWithdrawn(
        marketId: UInt64,
        protocol: String,
        amount: UFix64,
        yieldEarned: UFix64,
        timestamp: UFix64
    )

    access(all) fun emitMarketCreated(marketId: UInt64, question: String, endTime: UFix64, options: [String], yieldProtocol: String, creator: Address) {
        emit MarketCreated(marketId: marketId, question: question, endTime: endTime, options: options, yieldProtocol: yieldProtocol, creator: creator)
    }

    access(all) fun emitBetPlaced(marketId: UInt64, user: Address, selectedOption: String, amount: UFix64) {
        emit BetPlaced(marketId: marketId, user: user, selectedOption: selectedOption, amount: amount, timestamp: getCurrentBlock().timestamp)
    }

    access(all) fun emitMarketResolved(marketId: UInt64, winningOption: String, apys: {String: UFix64}) {
        emit MarketResolved(marketId: marketId, winningOption: winningOption, finalAPYs: apys, resolvedAt: getCurrentBlock().timestamp)
    }

    access(all) fun emitWinningsClaimed(marketId: UInt64, user: Address, payout: UFix64) {
        emit WinningsClaimed(marketId: marketId, user: user, payout: payout, timestamp: getCurrentBlock().timestamp)
    }

    access(all) fun emitYieldDeposited(marketId: UInt64, protocol: String, amount: UFix64) {
        emit YieldDeposited(marketId: marketId, protocol: protocol, amount: amount, timestamp: getCurrentBlock().timestamp)
    }

    access(all) fun emitYieldWithdrawn(marketId: UInt64, protocol: String, amount: UFix64, yieldEarned: UFix64) {
        emit YieldWithdrawn(marketId: marketId, protocol: protocol, amount: amount, yieldEarned: yieldEarned, timestamp: getCurrentBlock().timestamp)
    }

    init() {
        emit ContractInitialized()
    }
}

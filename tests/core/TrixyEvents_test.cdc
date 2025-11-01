import Test
import "TrixyEvents"

access(all) fun setup() {
    let err = Test.deployContract(
        name: "TrixyEvents",
        path: "../../contracts/core/TrixyEvents.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testContractInitialized() {
    log("TrixyEvents contract initialized successfully")
}

access(all) fun testEmitMarketCreated() {
    let marketId: UInt64 = 1
    let question = "Will BTC hit $100k?"
    let endTime = getCurrentBlock().timestamp + 86400.0
    let options = ["YES", "NO"]
    let yieldProtocol = "aave"
    let creator = 0x0000000000000007 as Address
    
    TrixyEvents.emitMarketCreated(
        marketId: marketId,
        question: question,
        endTime: endTime,
        options: options,
        yieldProtocol: yieldProtocol,
        creator: creator
    )
    
    log("Market created event emitted")
}

access(all) fun testEmitBetPlaced() {
    let marketId: UInt64 = 1
    let user: Address = 0x0000000000000008
    let selectedOption = "YES"
    let amount = 100.0
    
    TrixyEvents.emitBetPlaced(
        marketId: marketId,
        user: user,
        selectedOption: selectedOption,
        amount: amount
    )
    
    log("Bet placed event emitted")
}

access(all) fun testEmitMarketResolved() {
    let marketId: UInt64 = 1
    let winningOption = "YES"
    let apys: {String: UFix64} = {
        "aave": 12.5,
        "morpho": 15.3
    }
    
    TrixyEvents.emitMarketResolved(
        marketId: marketId,
        winningOption: winningOption,
        apys: apys
    )
    
    log("Market resolved event emitted")
}

access(all) fun testEmitWinningsClaimed() {
    let marketId: UInt64 = 1
    let user: Address = 0x0000000000000008
    let payout = 150.0
    
    TrixyEvents.emitWinningsClaimed(
        marketId: marketId,
        user: user,
        payout: payout
    )
    
    log("Winnings claimed event emitted")
}

access(all) fun testEmitYieldDeposited() {
    let marketId: UInt64 = 1
    let protocol = "aave"
    let amount = 1000.0
    
    TrixyEvents.emitYieldDeposited(
        marketId: marketId,
        protocol: protocol,
        amount: amount
    )
    
    log("Yield deposited event emitted")
}

access(all) fun testEmitYieldWithdrawn() {
    let marketId: UInt64 = 1
    let protocol = "aave"
    let amount = 1000.0
    let yieldEarned = 50.0
    
    TrixyEvents.emitYieldWithdrawn(
        marketId: marketId,
        protocol: protocol,
        amount: amount,
        yieldEarned: yieldEarned
    )
    
    log("Yield withdrawn event emitted")
}

access(all) fun testMultipleEventEmissions() {
    TrixyEvents.emitMarketCreated(
        marketId: 2,
        question: "Will ETH hit $5k?",
        endTime: getCurrentBlock().timestamp + 172800.0,
        options: ["YES", "NO"],
        yieldProtocol: "morpho",
        creator: 0x0000000000000007
    )
    
    TrixyEvents.emitBetPlaced(
        marketId: 2,
        user: 0x0000000000000008,
        selectedOption: "YES",
        amount: 100.0
    )
    
    TrixyEvents.emitBetPlaced(
        marketId: 2,
        user: 0x0000000000000009,
        selectedOption: "NO",
        amount: 150.0
    )
    
    TrixyEvents.emitYieldDeposited(
        marketId: 2,
        protocol: "morpho",
        amount: 250.0
    )
    
    log("Multiple events emitted successfully")
}

access(all) fun testEventParameterVariations() {
    let apys1: {String: UFix64} = {}
    TrixyEvents.emitMarketResolved(
        marketId: 10,
        winningOption: "YES",
        apys: apys1
    )
    
    let apys2: {String: UFix64} = {
        "aave": 5.2,
        "morpho": 8.1,
        "compound": 10.5
    }
    TrixyEvents.emitMarketResolved(
        marketId: 11,
        winningOption: "NO",
        apys: apys2
    )
    
    log("Event parameter variations tested")
}

access(all) fun testEventWithSpecialCharacters() {
    TrixyEvents.emitMarketCreated(
        marketId: 20,
        question: "Will BTC price be > $100,000 USD?",
        endTime: getCurrentBlock().timestamp + 86400.0,
        options: ["YES", "NO"],
        yieldProtocol: "aave-v3",
        creator: 0x0000000000000007
    )
    
    TrixyEvents.emitMarketResolved(
        marketId: 20,
        winningOption: "YES",
        apys: {
            "aave-v3": 12.5,
            "morpho-blue": 14.2
        }
    )
    
    log("Special character events emitted")
}

access(all) fun testEventWithLargeAmounts() {
    TrixyEvents.emitBetPlaced(
        marketId: 30,
        user: 0x0000000000000010,
        selectedOption: "YES",
        amount: 999999.999
    )
    
    TrixyEvents.emitYieldWithdrawn(
        marketId: 30,
        protocol: "aave",
        amount: 1000000.0,
        yieldEarned: 50000.0
    )
    
    log("Large amount events emitted")
}

access(all) fun testEventWithZeroValues() {
    TrixyEvents.emitBetPlaced(
        marketId: 40,
        user: 0x0000000000000011,
        selectedOption: "YES",
        amount: 0.0
    )
    
    TrixyEvents.emitYieldWithdrawn(
        marketId: 40,
        protocol: "morpho",
        amount: 0.0,
        yieldEarned: 0.0
    )
    
    log("Zero value events emitted")
}

access(all) fun testEventSequence() {
    let marketId: UInt64 = 50
    
    TrixyEvents.emitMarketCreated(
        marketId: marketId,
        question: "Test sequence?",
        endTime: getCurrentBlock().timestamp + 86400.0,
        options: ["YES", "NO"],
        yieldProtocol: "compound",
        creator: 0x0000000000000007
    )
    
    TrixyEvents.emitBetPlaced(
        marketId: marketId,
        user: 0x0000000000000008,
        selectedOption: "YES",
        amount: 100.0
    )
    
    TrixyEvents.emitYieldDeposited(
        marketId: marketId,
        protocol: "compound",
        amount: 100.0
    )
    
    TrixyEvents.emitMarketResolved(
        marketId: marketId,
        winningOption: "YES",
        apys: {"compound": 13.2}
    )
    
    TrixyEvents.emitYieldWithdrawn(
        marketId: marketId,
        protocol: "compound",
        amount: 100.0,
        yieldEarned: 5.0
    )
    
    TrixyEvents.emitWinningsClaimed(
        marketId: marketId,
        user: 0x0000000000000008,
        payout: 205.0
    )
    
    log("Event sequence completed successfully")
}

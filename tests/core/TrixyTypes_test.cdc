import Test
import "TrixyTypes"

access(all) fun setup() {
    let err = Test.deployContract(
        name: "TrixyTypes",
        path: "../../contracts/core/TrixyTypes.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testMarketStatusActive() {
    let status = TrixyTypes.MarketStatus.Active
    Test.assertEqual(TrixyTypes.MarketStatus.Active, status)
}

access(all) fun testMarketStatusResolved() {
    let status = TrixyTypes.MarketStatus.Resolved
    Test.assertEqual(TrixyTypes.MarketStatus.Resolved, status)
}

access(all) fun testMarketStatusCancelled() {
    let status = TrixyTypes.MarketStatus.Cancelled
    Test.assertEqual(TrixyTypes.MarketStatus.Cancelled, status)
}

access(all) fun testMarketStatusComparison() {
    let active = TrixyTypes.MarketStatus.Active
    let resolved = TrixyTypes.MarketStatus.Resolved
    let cancelled = TrixyTypes.MarketStatus.Cancelled
    
    Test.assertEqual(false, active == resolved)
    Test.assertEqual(false, resolved == cancelled)
    Test.assertEqual(false, cancelled == active)
}

access(all) fun testProtocolTypeIncrement() {
    let protocolType = TrixyTypes.ProtocolType.Increment
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType)
}

access(all) fun testBinaryPositionInitialization() {
    let position = TrixyTypes.BinaryPosition(
        yesShares: 100.0,
        noShares: 50.0
    )
    
    Test.assertEqual(100.0, position.yesShares)
    Test.assertEqual(50.0, position.noShares)
    Test.assertEqual(false, position.claimed)
    Test.assertEqual(0.0, position.yieldEarned)
}

access(all) fun testBinaryPositionSetClaimed() {
    var position = TrixyTypes.BinaryPosition(
        yesShares: 100.0,
        noShares: 50.0
    )
    
    Test.assertEqual(false, position.claimed)
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
}

access(all) fun testBinaryPositionSetYield() {
    var position = TrixyTypes.BinaryPosition(
        yesShares: 100.0,
        noShares: 50.0
    )
    
    Test.assertEqual(0.0, position.yieldEarned)
    position.setYield(amount: 10.5)
    Test.assertEqual(10.5, position.yieldEarned)
}

access(all) fun testBinaryPositionMultipleOperations() {
    var position = TrixyTypes.BinaryPosition(
        yesShares: 75.0,
        noShares: 25.0
    )
    
    position.setYield(amount: 5.0)
    Test.assertEqual(5.0, position.yieldEarned)
    
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
    
    position.setYield(amount: 7.5)
    Test.assertEqual(7.5, position.yieldEarned)
}

access(all) fun testProtocolStatsInitialization() {
    let stats = TrixyTypes.ProtocolStats(
        name: "Aave",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    Test.assertEqual("Aave", stats.name)
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, stats.protocolType)
    Test.assertEqual(0.0, stats.totalStaked)
    Test.assertEqual(0 as UInt64, stats.participantCount)
    Test.assertEqual(0.0, stats.currentAPY)
    Test.assertEqual(0.0, stats.accumulatedYield)
}

access(all) fun testProtocolStatsUpdateStake() {
    var stats = TrixyTypes.ProtocolStats(
        name: "Morpho",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    stats.updateStake(amount: 100.0)
    Test.assertEqual(100.0, stats.totalStaked)
    Test.assertEqual(1 as UInt64, stats.participantCount)
    
    stats.updateStake(amount: 50.0)
    Test.assertEqual(150.0, stats.totalStaked)
    Test.assertEqual(2 as UInt64, stats.participantCount)
}

access(all) fun testProtocolStatsUpdateAPY() {
    var stats = TrixyTypes.ProtocolStats(
        name: "Compound",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    Test.assertEqual(0.0, stats.currentAPY)
    stats.updateAPY(newAPY: 12.5)
    Test.assertEqual(12.5, stats.currentAPY)
    
    stats.updateAPY(newAPY: 15.3)
    Test.assertEqual(15.3, stats.currentAPY)
}

access(all) fun testProtocolStatsAddYield() {
    var stats = TrixyTypes.ProtocolStats(
        name: "TestProtocol",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    Test.assertEqual(0.0, stats.accumulatedYield)
    stats.addYield(amount: 5.5)
    Test.assertEqual(5.5, stats.accumulatedYield)
    
    stats.addYield(amount: 2.3)
    Test.assertEqual(7.8, stats.accumulatedYield)
}

access(all) fun testProtocolStatsComplexOperations() {
    var stats = TrixyTypes.ProtocolStats(
        name: "Complex",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    stats.updateStake(amount: 1000.0)
    stats.updateStake(amount: 500.0)
    stats.updateAPY(newAPY: 18.5)
    stats.addYield(amount: 25.0)
    
    Test.assertEqual(1500.0, stats.totalStaked)
    Test.assertEqual(2 as UInt64, stats.participantCount)
    Test.assertEqual(18.5, stats.currentAPY)
    Test.assertEqual(25.0, stats.accumulatedYield)
}

access(all) fun testUserPositionInitialization() {
    let position = TrixyTypes.UserPosition(
        protocol: "Aave",
        amount: 500.0
    )
    
    Test.assertEqual("Aave", position.protocol)
    Test.assertEqual(500.0, position.amount)
    Test.assertEqual(false, position.claimed)
    Test.assertEqual(0.0, position.yieldEarned)
}

access(all) fun testUserPositionSetClaimed() {
    var position = TrixyTypes.UserPosition(
        protocol: "Morpho",
        amount: 1000.0
    )
    
    Test.assertEqual(false, position.claimed)
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
}

access(all) fun testUserPositionSetYield() {
    var position = TrixyTypes.UserPosition(
        protocol: "Compound",
        amount: 750.0
    )
    
    Test.assertEqual(0.0, position.yieldEarned)
    position.setYield(amount: 25.5)
    Test.assertEqual(25.5, position.yieldEarned)
}

access(all) fun testPredictionMarketInfoInitialization() {
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0
    
    let marketInfo = TrixyTypes.PredictionMarketInfo(
        id: 1,
        question: "Will BTC hit 100k?",
        startTime: currentTime,
        endTime: endTime,
        yieldProtocol: "aave",
        status: TrixyTypes.MarketStatus.Active,
        outcome: nil,
        totalYesShares: 1000.0,
        totalNoShares: 500.0,
        totalYieldEarned: 50.0,
        totalPool: 1550.0,
        resolutionMethod: TrixyTypes.ResolutionMethod.Oracle,
        oracleCriteria: TrixyTypes.OracleResolutionCriteria(
            symbol: "BTC",
            targetPrice: 100000.0,
            comparisonType: "ABOVE",
            targetPrice2: nil,
            resolutionDeadline: endTime + 86400.0
        )
    )
    
    Test.assertEqual(1 as UInt64, marketInfo.id)
    Test.assertEqual("Will BTC hit 100k?", marketInfo.question)
    Test.assertEqual("aave", marketInfo.yieldProtocol)
    Test.assertEqual(TrixyTypes.MarketStatus.Active, marketInfo.status)
    Test.assertEqual(nil, marketInfo.outcome)
    Test.assertEqual(1000.0, marketInfo.totalYesShares)
    Test.assertEqual(500.0, marketInfo.totalNoShares)
    Test.assertEqual(50.0, marketInfo.totalYieldEarned)
    Test.assertEqual(1550.0, marketInfo.totalPool)
}

access(all) fun testGetProtocolTypeIncrement() {
    let protocolType = TrixyTypes.getProtocolType("Increment")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType)
}

access(all) fun testGetProtocolTypeUnknown() {
    let protocolType = TrixyTypes.getProtocolType("Unknown")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType)
}

access(all) fun testGetProtocolTypeEmptyString() {
    let protocolType = TrixyTypes.getProtocolType("")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType)
}

access(all) fun testGetProtocolTypeCaseSensitive() {
    let protocolType1 = TrixyTypes.getProtocolType("increment")
    let protocolType2 = TrixyTypes.getProtocolType("INCREMENT")
    
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType1)
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, protocolType2)
}

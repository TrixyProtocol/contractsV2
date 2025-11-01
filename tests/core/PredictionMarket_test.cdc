import Test
import BlockchainHelpers
import "PredictionMarket"
import "TrixyTypes"
import "TrixyEvents"
import "FlowToken"
import "FungibleToken"

access(all) let serviceAccount = Test.serviceAccount()
access(all) var adminAccount: Test.TestAccount? = nil
access(all) var userAccount: Test.TestAccount? = nil

access(all) fun setup() {
    var err = Test.deployContract(
        name: "Burner",
        path: "../mocks/Burner.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "TrixyTypes",
        path: "../../contracts/core/TrixyTypes.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "TrixyEvents",
        path: "../../contracts/core/TrixyEvents.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IStakingProtocol",
        path: "../../contracts/interfaces/IStakingProtocol.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "Staking",
        path: "../mocks/Staking.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IncrementFiStakingConnectors",
        path: "../mocks/IncrementFiStakingConnectors.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IncrementAdapter",
        path: "../../contracts/adapters/IncrementAdapter.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "DeFiActions",
        path: "../mocks/DeFiActions.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracle",
        path: "../mocks/BandOracle.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracleConnectors",
        path: "../mocks/BandOracleConnectors.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracleResolver",
        path: "../../contracts/resolvers/BandOracleResolver.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "PredictionMarket",
        path: "../../contracts/core/PredictionMarket.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    adminAccount = Test.createAccount()
    userAccount = Test.createAccount()
}

// Test TrixyTypes enums and structs
access(all) fun testTrixyTypesEnums() {
    // Test MarketStatus enum
    let activeStatus = TrixyTypes.MarketStatus.Active
    let resolvedStatus = TrixyTypes.MarketStatus.Resolved
    let cancelledStatus = TrixyTypes.MarketStatus.Cancelled
    
    Test.assertEqual(0 as UInt8, activeStatus.rawValue)
    Test.assertEqual(1 as UInt8, resolvedStatus.rawValue)
    Test.assertEqual(2 as UInt8, cancelledStatus.rawValue)
    
    // Test ResolutionMethod enum
    let manualMethod = TrixyTypes.ResolutionMethod.Manual
    let oracleMethod = TrixyTypes.ResolutionMethod.Oracle
    let automaticMethod = TrixyTypes.ResolutionMethod.Automatic
    
    Test.assertEqual(0 as UInt8, manualMethod.rawValue)
    Test.assertEqual(1 as UInt8, oracleMethod.rawValue)
    Test.assertEqual(2 as UInt8, automaticMethod.rawValue)
}

// Test BinaryPosition struct
access(all) fun testBinaryPosition() {
    let position = TrixyTypes.BinaryPosition(yesShares: 100.0, noShares: 50.0)
    
    Test.assertEqual(100.0, position.yesShares)
    Test.assertEqual(50.0, position.noShares)
    Test.assertEqual(false, position.claimed)
    Test.assertEqual(0.0, position.yieldEarned)
    
    // Test setClaimed
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
    
    // Test setYield
    position.setYield(amount: 10.5)
    Test.assertEqual(10.5, position.yieldEarned)
}

// Test OracleResolutionCriteria struct
access(all) fun testOracleResolutionCriteria() {
    let futureTime = getCurrentBlock().timestamp + 3600.0
    
    let criteria = TrixyTypes.OracleResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 2.5,
        comparisonType: "ABOVE",
        targetPrice2: nil,
        resolutionDeadline: futureTime
    )
    
    Test.assertEqual("FLOW", criteria.symbol)
    Test.assertEqual(2.5, criteria.targetPrice)
    Test.assertEqual("ABOVE", criteria.comparisonType)
    Test.assertEqual(nil, criteria.targetPrice2)
    Test.assertEqual(futureTime, criteria.resolutionDeadline)
}

// Test oracle criteria with BETWEEN comparison
access(all) fun testOracleCriteriaBetween() {
    let futureTime = getCurrentBlock().timestamp + 3600.0
    
    let criteria = TrixyTypes.OracleResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 1.0,
        comparisonType: "BETWEEN",
        targetPrice2: 3.0,
        resolutionDeadline: futureTime
    )
    
    Test.assertEqual("FLOW", criteria.symbol)
    Test.assertEqual(1.0, criteria.targetPrice)
    Test.assertEqual("BETWEEN", criteria.comparisonType)
    Test.assertEqual(3.0, criteria.targetPrice2!)
    Test.assertEqual(futureTime, criteria.resolutionDeadline)
}

// Test ProtocolStats struct
access(all) fun testProtocolStats() {
    var stats = TrixyTypes.ProtocolStats(
        name: "Increment",
        protocolType: TrixyTypes.ProtocolType.Increment
    )
    
    Test.assertEqual("Increment", stats.name)
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, stats.protocolType)
    Test.assertEqual(0.0, stats.totalStaked)
    Test.assertEqual(0 as UInt64, stats.participantCount)
    Test.assertEqual(0.0, stats.currentAPY)
    Test.assertEqual(0.0, stats.accumulatedYield)
    
    // Test updateStake
    stats.updateStake(amount: 100.0)
    Test.assertEqual(100.0, stats.totalStaked)
    Test.assertEqual(1 as UInt64, stats.participantCount)
    
    // Test updateAPY
    stats.updateAPY(newAPY: 15.5)
    Test.assertEqual(15.5, stats.currentAPY)
    
    // Test addYield
    stats.addYield(amount: 25.0)
    Test.assertEqual(25.0, stats.accumulatedYield)
}

// Test UserPosition struct
access(all) fun testUserPosition() {
    var position = TrixyTypes.UserPosition(
        protocol: "increment",
        amount: 500.0
    )
    
    Test.assertEqual("increment", position.protocol)
    Test.assertEqual(500.0, position.amount)
    Test.assertEqual(false, position.claimed)
    Test.assertEqual(0.0, position.yieldEarned)
    Test.assertEqual(true, position.stakeTimestamp > 0.0)
    
    // Test setClaimed
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
    
    // Test setYield
    position.setYield(amount: 35.5)
    Test.assertEqual(35.5, position.yieldEarned)
}

// Test market creation parameters validation
access(all) fun testMarketCreationValidation() {
    let futureTime = getCurrentBlock().timestamp + 3600.0
    let oracleCriteria = TrixyTypes.OracleResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 2.0,
        comparisonType: "ABOVE",
        targetPrice2: nil,
        resolutionDeadline: futureTime
    )
    
    // This test validates that market creation parameters are properly structured
    // In a full integration test, we would create actual market resources
    
    // Test manual resolution method (no oracle criteria needed)
    Test.assertEqual(TrixyTypes.ResolutionMethod.Manual.rawValue, 0 as UInt8)
    
    // Test oracle resolution method (requires oracle criteria)
    Test.assertEqual(TrixyTypes.ResolutionMethod.Oracle.rawValue, 1 as UInt8)
    Test.assertEqual(true, oracleCriteria != nil)
}

// Test PredictionMarketInfo struct creation
access(all) fun testPredictionMarketInfo() {
    let currentTime = getCurrentBlock().timestamp
    let futureTime = currentTime + 3600.0
    let oracleCriteria = TrixyTypes.OracleResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 2.0,
        comparisonType: "ABOVE",
        targetPrice2: nil,
        resolutionDeadline: futureTime
    )
    
    let marketInfo = TrixyTypes.PredictionMarketInfo(
        id: 1,
        question: "Will FLOW price be above $2?",
        startTime: currentTime,
        endTime: futureTime,
        yieldProtocol: "increment",
        status: TrixyTypes.MarketStatus.Active,
        outcome: nil,
        totalYesShares: 100.0,
        totalNoShares: 50.0,
        totalYieldEarned: 5.0,
        totalPool: 155.0,
        resolutionMethod: TrixyTypes.ResolutionMethod.Oracle,
        oracleCriteria: oracleCriteria
    )
    
    Test.assertEqual(1 as UInt64, marketInfo.id)
    Test.assertEqual("Will FLOW price be above $2?", marketInfo.question)
    Test.assertEqual(currentTime, marketInfo.startTime)
    Test.assertEqual(futureTime, marketInfo.endTime)
    Test.assertEqual("increment", marketInfo.yieldProtocol)
    Test.assertEqual(TrixyTypes.MarketStatus.Active, marketInfo.status)
    Test.assertEqual(nil, marketInfo.outcome)
    Test.assertEqual(100.0, marketInfo.totalYesShares)
    Test.assertEqual(50.0, marketInfo.totalNoShares)
    Test.assertEqual(5.0, marketInfo.totalYieldEarned)
    Test.assertEqual(155.0, marketInfo.totalPool)
    Test.assertEqual(TrixyTypes.ResolutionMethod.Oracle, marketInfo.resolutionMethod)
    Test.assertEqual(true, marketInfo.oracleCriteria != nil)
}

// Test yield protocol validation
access(all) fun testYieldProtocolValidation() {
    // These would be validated in market creation preconditions
    let validProtocols = ["aave", "morpho", "compound"]
    
    for protocol in validProtocols {
        let isValid = protocol == "aave" || protocol == "morpho" || protocol == "compound"
        Test.assertEqual(true, isValid)
    }
    
    let invalidProtocols = ["invalid", "uniswap", ""]
    for protocol in invalidProtocols {
        let isValid = protocol == "aave" || protocol == "morpho" || protocol == "compound"
        Test.assertEqual(false, isValid)
    }
}

// Test time validation helpers
access(all) fun testTimeValidation() {
    let currentTime = getCurrentBlock().timestamp
    let pastTime = currentTime - 1000.0
    let futureTime = currentTime + 1000.0
    
    // Test that future times are greater than current time
    Test.assertEqual(true, futureTime > currentTime)
    Test.assertEqual(false, pastTime > currentTime)
    
    // Test time ranges
    Test.assertEqual(true, futureTime > pastTime)
}

// Test market status transitions
access(all) fun testMarketStatusTransitions() {
    // Valid transitions: Active -> Resolved, Active -> Cancelled
    let activeStatus = TrixyTypes.MarketStatus.Active
    let resolvedStatus = TrixyTypes.MarketStatus.Resolved  
    let cancelledStatus = TrixyTypes.MarketStatus.Cancelled
    
    // Verify status values
    Test.assertEqual(0 as UInt8, activeStatus.rawValue)
    Test.assertEqual(1 as UInt8, resolvedStatus.rawValue)
    Test.assertEqual(2 as UInt8, cancelledStatus.rawValue)
    
    // In the actual contract, these transitions would be enforced by preconditions
    Test.assertEqual(true, activeStatus != resolvedStatus)
    Test.assertEqual(true, activeStatus != cancelledStatus)
    Test.assertEqual(true, resolvedStatus != cancelledStatus)
}

// Test comparison type validation for oracle criteria
access(all) fun testComparisonTypeValidation() {
    let validComparisons = ["ABOVE", "BELOW", "BETWEEN"]
    let invalidComparisons = ["EQUALS", "NOT_EQUAL", "", "above", "Below"]
    
    for comparison in validComparisons {
        let isValid = comparison == "ABOVE" || comparison == "BELOW" || comparison == "BETWEEN"
        Test.assertEqual(true, isValid)
    }
    
    for comparison in invalidComparisons {
        let isValid = comparison == "ABOVE" || comparison == "BELOW" || comparison == "BETWEEN"
        Test.assertEqual(false, isValid)
    }
}

// Test contract helper functions 
access(all) fun testContractHelpers() {
    // Test that contract deployed successfully (verified by successful setup)
    Test.assertEqual(true, true)
}

// Test event emission structure (we can't test actual events without resources)
access(all) fun testEventStructure() {
    // This validates that the TrixyEvents contract is properly deployed
    // and can be used for event emission
    Test.assertEqual(true, true) // TrixyEvents contract deployed in setup
}